import { ExpansionViewModel } from '../../viewmodel/ExpansionViewModel';
import { ExpansionRenderPiece } from '../../viewmodel/ExpansionRenderPiece';
import { ExpansionPiece, ExpansionPile } from '../../model/game/ExpansionState';
import { CHARACTER_PARTS, CHARACTER_RECIPES } from '../../model/game/ExpansionTable';
import { SemanticColors, FontTokens, SpacingTokens, RadiusTokens } from '../../common/DesignTokens';
import { range } from '../../common/Range';
import { ExpansionArt } from '../../common/ExpansionArt';
import { ExpansionArcade } from '../../model/game/ExpansionArcade';

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
  food(index: number): Resource { return index === 0 ? $r('app.string.expansion_food_0') : index === 1 ? $r('app.string.expansion_food_1') : $r('app.string.expansion_food_2'); }
  build() {
    Column({ space: SpacingTokens.base }) {
      if (this.gameId === 'solitaire') { this.Solitaire() }
      if (this.gameId === 'characters') { this.Characters() }
      if (this.gameId === 'restaurant') { this.Restaurant() }
      if (this.gameId === 'roomdefense') {
        Text($r('app.string.expansion_coins', this.vm.state.data[0], this.vm.state.data[1])).fontColor(SemanticColors.textPrimary)
        Button($r('app.string.expansion_repair')).enabled(this.vm.state.data[0] >= 25 && this.vm.state.data[1] < 100)
          .onClick(() => { this.vm.tap(6); })
      }
      if (this.gameId === 'rhythm') {
        Row({ space: SpacingTokens.xs }) {
          ForEach(range(4), (lane: number) => {
            Button($r('app.string.expansion_key', lane + 1)).layoutWeight(1).height($r('app.float.expansion_control_height')).id('rhythm-key-' + lane)
              .onClick(() => { this.vm.tap(lane); })
          }, (lane: number) => lane.toString())
        }.width('100%')
      }
    }.width('100%').padding(SpacingTokens.sm).backgroundImage(ExpansionArt.board(this.gameId)).backgroundImageSize({ width: '100%', height: '100%' }).borderRadius(RadiusTokens.base)
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
  @Builder
  Characters() {
    Column({ space: SpacingTokens.base }) {
      Text($r('app.string.expansion_character', CHARACTER_RECIPES[this.vm.state.cursor].result)).fontSize(FontTokens.sizeTitle).fontColor(SemanticColors.textPrimary)
      Text(this.vm.state.tray.map((part: number) => CHARACTER_PARTS[part]).join(' + ')).height(48).fontSize(FontTokens.sizeTitle).fontColor(SemanticColors.primary)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(this.vm.state.board, (part: number, option: number) => {
          Button(CHARACTER_PARTS[part]).width('29%').height(64).margin(SpacingTokens.xs).fontSize(FontTokens.sizeTitle)
            .onClick(() => { this.vm.tap(option); })
        }, (part: number) => part.toString())
      }.width('100%')
      Row({ space: SpacingTokens.sm }) {
        Button($r('app.string.expansion_clear')).layoutWeight(1).onClick(() => { this.vm.tap(100); })
        Button($r('app.string.expansion_check')).layoutWeight(1).onClick(() => { this.vm.action(); })
      }.width('100%')
    }.width('100%')
  }
  @Builder
  Restaurant() {
    Column({ space: SpacingTokens.base }) {
      Text($r('app.string.expansion_money', this.vm.state.data[0])).fontColor(SemanticColors.textPrimary)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(this.vm.worldPieces.filter((rendered: ExpansionRenderPiece) => rendered.piece.kind === 19), (rendered: ExpansionRenderPiece) => {
          Button({ type: ButtonType.Normal }) {
            Column({ space: SpacingTokens.sm }) {
              Image(ExpansionArt.person(rendered.piece.id % 6)).width(52).height(52).objectFit(ImageFit.Contain).accessibilityLevel('no')
              Image(ExpansionArt.food(rendered.piece.color)).width(32).height(32).objectFit(ImageFit.Contain).accessibilityLevel('no')
              Text(this.food(rendered.piece.color)).fontColor(SemanticColors.textPrimary)
              Text($r('app.string.expansion_customer', rendered.piece.id, Math.ceil(rendered.piece.age))).fontSize(FontTokens.sizeCaption).fontColor(rendered.piece.age < 8 ? SemanticColors.warningText : SemanticColors.textSecondary)
              Progress({ value: Math.max(0, rendered.piece.age), total: ExpansionArcade.customerPatience(this.vm.state.level), type: ProgressType.Linear })
                .width('90%').color(rendered.piece.age < 8 ? SemanticColors.error : SemanticColors.success)
              if (this.vm.state.board[rendered.piece.color] > 0) {
                Text($r('app.string.restaurant_serve')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.primary)
              }
            }.padding(SpacingTokens.sm)
          }.width('47%').margin(SpacingTokens.xs).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.base)
            .id('restaurant-customer-' + rendered.id).onClick(() => { this.vm.tap(100 + rendered.piece.id); })
        }, (rendered: ExpansionRenderPiece) => rendered.id.toString())
      }.width('100%')
      Row({ space: SpacingTokens.sm }) {
        ForEach(range(3), (food: number) => {
          Button({ type: ButtonType.Normal }) {
            Column({ space: SpacingTokens.sm }) {
              Image(ExpansionArt.food(food)).width(48).height(48).objectFit(ImageFit.Contain).accessibilityLevel('no')
              Text(this.food(food)).fontColor(SemanticColors.textPrimary)
              Text($r('app.string.expansion_food_stock', this.vm.state.board[food])).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.textSecondary)
              if (this.vm.state.pieces.some((p: ExpansionPiece) => p.kind === 20 && p.color === food)) { Text($r('app.string.expansion_cooking')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.primary) }
              else { Text($r('app.string.restaurant_prepare')).fontSize(FontTokens.sizeCaption).fontColor(SemanticColors.primary) }
            }.padding(SpacingTokens.sm)
          }.layoutWeight(1).backgroundColor(SemanticColors.surface).borderRadius(RadiusTokens.base)
            .id('restaurant-cook-' + food).onClick(() => { this.vm.tap(food); })
        }, (food: number) => food.toString())
      }.width('100%')
    }.width('100%')
  }
}
