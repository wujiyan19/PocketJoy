import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionPile } from '../../model/game/ExpansionState';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';

@ComponentV2
export struct ExpansionExtras {
  @Param gameId: string = '';
  @Param vm: ExpansionViewModel = new ExpansionViewModel();
  cardText(card: number): string {
    if (this.vm.state.pieces[card].w === 0) { return '▧'; }
    const rank: number = card % 13; return ['♤', '♡', '♢', '♧'][Math.floor(card / 13)] + ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][rank];
  }
  cardColor(card: number): Resource {
    if (this.vm.state.pieces[card].w === 0) { return SemanticColors.textSecondary; }
    const suit: number = Math.floor(card / 13);
    return suit === 1 || suit === 2 ? SemanticColors.errorText : SemanticColors.textPrimary;
  }
  top(pile: number): number { const cards: number[] = this.vm.state.piles[pile].cards; return cards.length > 0 ? cards[cards.length - 1] : -1; }
  tableauHeight(): number { return Math.max(200, ...this.vm.state.piles.slice(2, 9).map((p: ExpansionPile) => p.cards.length * 28 + 45)); }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (this.gameId === 'solitaire') { this.Solitaire() }
      if (this.gameId === 'rhythm') {
        Row({ space: SpacingTokens.xs }) {
          ForEach(range(4), (lane: number) => {
            Button($r('app.string.expansion_key', lane + 1)).layoutWeight(1).height($r('app.float.expansion_control_height')).id('rhythm-key-' + lane)
              .onClick(() => { this.vm.tap(lane); })
          }, (lane: number) => lane.toString())
        }.width('100%')
      }
    }.width('100%').padding(SpacingTokens.sm).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base).clip(true)
  }
  @Builder
  Card(card: number) {
    Button({ type: ButtonType.Normal }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text(this.cardText(card)).fontSize(FontTokens.sizeBody).fontFamily(FontTokens.family).fontColor(this.cardColor(card))
          .padding({ top: SpacingTokens.xs, left: SpacingTokens.xs }).hitTestBehavior(HitTestMode.None)
      }.width('100%').height('100%')
    }.width('100%').height(45).padding(0)
      .backgroundImage(this.vm.state.pieces[card].w === 0 ? $r('app.media.exp_card_back') : $r('app.media.exp_card_front')).backgroundImageSize(ImageSize.Cover)
      .fontSize(FontTokens.sizeBody).fontColor(this.cardColor(card)).backgroundColor(SemanticColors.surface)
      .borderRadius(RadiusTokens.xs).border({ width: this.vm.state.selected === card ? 2 : 1, color: this.vm.state.selected === card ? SemanticColors.primary : SemanticColors.border })
      .onClick(() => { this.vm.tap(card); })
  }
  @Builder
  Solitaire() {
    Column({ space: SpacingTokens.base }) {
      Row({ space: SpacingTokens.sm }) {
        Button($r('app.string.expansion_stock', this.vm.state.piles[0].cards.length)).layoutWeight(1).id('solitaire-stock')
          .onClick(() => { this.vm.tap(100); })
        Column() {
          if (this.vm.state.piles[1].cards.length > 0) {
            ForEach(this.vm.state.piles[1].cards.slice(-1), (card: number) => {
              this.Card(card)
            }, (card: number) => card.toString())
          } else { Text('○').fontColor(SemanticColors.textSecondary) }
        }.layoutWeight(1).height(45).borderRadius(RadiusTokens.xs).border({ width: 1, color: SemanticColors.border }).id('solitaire-waste')
        Button($r('app.string.expansion_foundation')).layoutWeight(1).onClick(() => { this.vm.tap(101); })
      }.width('100%')
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(4), (suit: number) => {
          Button(this.top(9 + suit) >= 0 ? this.cardText(this.top(9 + suit)) : ['♤', '♡', '♢', '♧'][suit], { type: ButtonType.Normal })
            .layoutWeight(1).height(44).fontFamily(FontTokens.family).fontColor(suit === 1 || suit === 2 ? SemanticColors.errorText : SemanticColors.textPrimary)
            .backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.sm).onClick(() => { this.vm.tap(109 + suit); })
        }, (suit: number) => suit.toString())
      }.width('100%')
      Row({ space: 2 }) {
        ForEach(range(7), (col: number) => {
          Stack({ alignContent: Alignment.TopStart }) {
            Button('K', { type: ButtonType.Normal }).width('100%').height(36).padding(0).backgroundColor(SemanticColors.primaryLight)
              .fontColor(SemanticColors.textSecondary).borderRadius(RadiusTokens.xs).onClick(() => { this.vm.tap(102 + col); })
            ForEach(this.vm.state.piles[2 + col].cards, (card: number, pos: number) => {
              Column() { this.Card(card) }.width('100%').translate({ y: pos * 28 })
            }, (card: number) => card.toString())
          }.layoutWeight(1).height(this.tableauHeight())
        }, (col: number) => col.toString())
      }.width('100%')
    }.width('100%')
  }
}
