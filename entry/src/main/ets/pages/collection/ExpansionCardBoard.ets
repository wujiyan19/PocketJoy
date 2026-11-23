import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionPile } from '../../model/game/ExpansionState';
import { CHESS_IDS } from '../../model/game/ExpansionChess';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';
import { GameArtTile } from '../../components/GameArtTile';
import { ExpansionChessBoard } from './ExpansionChessBoard';

@ComponentV2
export struct ExpansionCardBoard {
  @Local spiderViewportWidth: number = 320;
  @Computed get spiderCardWidth(): number {
    const gap: number = SpacingTokens.xs;
    if (this.spiderViewportWidth >= 10 * 48 + 9 * gap) { return 48; }
    const fullColumns: number = Math.max(1, Math.min(9, Math.floor((this.spiderViewportWidth - 22) / (44 + gap))));
    return (this.spiderViewportWidth - fullColumns * gap) / (fullColumns + 0.5);
  }
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  cardText(card: number): string {
    if (this.gameId === 'spider' && this.vm.state.pieces[card].w === 0) { return '▧'; }
    return (this.gameId === 'spider' ? '♤' : ['♤', '♡', '♢', '♧'][Math.floor(card / 13)]) + ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][card % 13];
  }
  cardColor(card: number): Resource {
    if (this.gameId === 'spider') { return SemanticColors.textPrimary; }
    const suit: number = Math.floor(card / 13);
    return suit === 1 || suit === 2 ? SemanticColors.error : SemanticColors.textPrimary;
  }
  slotColor(slot: number): Resource {
    const cards: number[] = this.vm.state.piles[8 + slot].cards;
    if (cards.length > 0) { return this.cardColor(cards[cards.length - 1]); }
    return slot === 5 || slot === 6 ? SemanticColors.error : SemanticColors.textPrimary;
  }
  spiderOffset(pile: ExpansionPile, pos: number): number {
    return pile.cards.slice(0, pos).reduce((y: number, card: number) => y + (this.vm.state.pieces[card].w === 0 ? 10 : 25), 0);
  }
  tableauHeight(): number {
    if (this.gameId === 'spider') { return Math.max(135, ...this.vm.state.piles.slice(0, 10).map((pile: ExpansionPile) => this.spiderOffset(pile, Math.max(0, pile.cards.length - 1)) + 62)); }
    return Math.max(230, ...this.vm.state.piles.slice(0, 8).map((pile: ExpansionPile) => pile.cards.length * 24 + 40));
  }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (CHESS_IDS.includes(this.gameId)) { ExpansionChessBoard({ gameId: this.gameId, vm: this.vm }) }
      if (this.gameId === 'spider' || this.gameId === 'freecell') { this.Solitaire() }
    }.width('100%').padding(SpacingTokens.sm)
      .backgroundImage(this.gameId === 'spider' || this.gameId === 'xiangqi' ? ExpansionArt.board(this.gameId) : '')
      .backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
      .enabled(CHESS_IDS.includes(this.gameId) || !this.vm.computerThinking)
  }
  @Builder
  SpiderCard(card: number) {
    Button() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.vm.state.pieces[card].w === 0 ? $r('app.media.exp_card_back') : $r('app.media.exp_card_front'))
          .width('100%').height('100%').objectFit(ImageFit.Fill)
        if (this.vm.state.pieces[card].w !== 0) {
          Text(this.cardText(card)).fontSize(FontTokens.sizeBodyLarge).fontWeight(FontWeight.Bold).fontColor(this.cardColor(card))
            .padding({ left: SpacingTokens.xs, top: 2 }).id('spider-open-' + card)
        }
      }.width('100%').height('100%')
    }.type(ButtonType.Normal).width(this.spiderCardWidth).height(62).padding(0).backgroundColor(Color.Transparent).borderRadius(RadiusTokens.sm)
      .border({ width: this.vm.state.selected === card ? 2 : 0, color: SemanticColors.primary })
      .accessibilityText(this.cardText(card)).onClick(() => { this.vm.tap(card); })
  }
  @Builder
  Card(card: number) {
    Column() {
      GameArtTile({ image: $r('app.media.exp_card_front'),
        label: this.cardText(card), description: this.cardText(card), textColor: this.cardColor(card),
        labelAtTop: true,
        selected: this.vm.state.selected === card, onTap: () => { this.vm.tap(card); } })
    }.width(52).height(62)
  }
  @Builder
  FreecellSlots(first: number, label: Resource) {
    Column({ space: SpacingTokens.xs }) {
      Text(label).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
      Row({ space: SpacingTokens.xs }) {
        ForEach(range(4), (i: number) => {
          Button(this.vm.state.piles[8 + first + i].cards.length > 0 ?
            this.cardText(this.vm.state.piles[8 + first + i].cards[this.vm.state.piles[8 + first + i].cards.length - 1]) :
            first === 0 ? '○' : ['♤', '♡', '♢', '♧'][i], { type: ButtonType.Normal })
            .layoutWeight(1).height(48).padding(0).borderRadius(RadiusTokens.sm).fontColor(this.slotColor(first + i))
            .backgroundColor(first === 0 ? SemanticColors.surface : SemanticColors.selectionSurface)
            .id('freecell-slot-' + (first + i)).onClick(() => {
              if (this.vm.state.selected >= 0) { this.vm.tap(208 + first + i); }
              else if (first === 0 && this.vm.state.piles[8 + i].cards.length > 0) { this.vm.tap(this.vm.state.piles[8 + i].cards[0]); }
            })
        }, (i: number) => i.toString())
      }.width('100%')
    }.layoutWeight(1)
  }
  @Builder
  Solitaire() {
    Column({ space: SpacingTokens.base }) {
      Column({ space: SpacingTokens.base }) {
        if (this.gameId === 'spider') {
          Row({ space: SpacingTokens.md }) {
            Button($r('app.string.expansion_stock', this.vm.state.piles[10].cards.length)).id('spider-stock')
              .enabled(this.vm.state.piles[10].cards.length > 0 && this.vm.state.piles.slice(0, 10).every((p: ExpansionPile) => p.cards.length > 0))
              .onClick(() => { this.vm.tap(900); })
            Text($r('app.string.spider_sets_done', this.vm.state.data[0])).fontColor(SemanticColors.textPrimary).fontSize(FontTokens.sizeBody).id('spider-done')
          }.width('100%').justifyContent(FlexAlign.Center)
          if (this.spiderViewportWidth < 10 * 48 + 9 * SpacingTokens.xs) {
            Text($r('app.string.spider_columns_hint')).fontSize(FontTokens.sizeBodySmall).fontColor(SemanticColors.textSecondary)
              .id('spider-columns-hint')
          }
        } else {
          Row({ space: SpacingTokens.md }) {
            this.FreecellSlots(0, $r('app.string.freecell_reserve'))
            this.FreecellSlots(4, $r('app.string.freecell_foundations'))
          }.width('100%')
          Text($r('app.string.freecell_columns_hint')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
        }
        Scroll() {
          Row({ space: SpacingTokens.xs }) {
            ForEach(range(this.gameId === 'spider' ? 10 : 8), (col: number) => {
              Stack({ alignContent: Alignment.TopStart }) {
                Button('○', { type: ButtonType.Normal }).width(this.gameId === 'freecell' ? 52 : this.spiderCardWidth).height(62).backgroundColor(SemanticColors.primaryLight).onClick(() => { this.vm.tap(200 + col); })
                ForEach(this.vm.state.piles[col].cards, (card: number, pos: number) => {
                  Column() {
                    if (this.gameId === 'spider') { this.SpiderCard(card) } else { this.Card(card) }
                  }.translate({ y: this.gameId === 'spider' ? this.spiderOffset(this.vm.state.piles[col], pos) : pos * 24 })
                    .id(this.gameId === 'spider' ? 'spider-card-' + col + '-' + pos : 'freecell-card-' + col + '-' + pos + '-' + card)
                }, (card: number) => card.toString())
              }.width(this.gameId === 'freecell' ? 52 : this.spiderCardWidth).height(this.tableauHeight()).id(this.gameId === 'spider' ? 'spider-pile-' + col : 'freecell-pile-' + col)
            }, (col: number) => col.toString())
          }
        }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Auto)
          .id(this.gameId === 'spider' ? 'spider-tableau' : 'freecell-tableau')
          .onAreaChange((oldArea: Area, area: Area) => {
            if (this.gameId === 'spider' && Number(area.width) > 0) { this.spiderViewportWidth = Number(area.width); }
          })
      }.width('100%').backgroundImage(this.gameId === 'freecell' ? ExpansionArt.board(this.gameId) : '')
        .backgroundImageSize({ width: '100%', height: '100%' })
      if (this.gameId === 'freecell') {
        Row({ space: SpacingTokens.sm }) {
          Button($r('app.string.expansion_foundation')).layoutWeight(1).enabled(this.vm.state.selected >= 0).id('freecell-home')
            .onClick(() => { this.vm.tap(900); })
          Button($r('app.string.expansion_undo')).layoutWeight(1).enabled(this.vm.canUndo).id('freecell-undo').onClick(() => { this.vm.undo(); })
        }.width('100%')
      }
    }.width('100%')
  }
}
