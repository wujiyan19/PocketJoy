@Builder
export function GameBoardArt(image: Resource) {
  // Render SVG through Image on older supported versions of ArkUI.
  Image(image).width('100%').height('100%').objectFit(ImageFit.Fill)
    .draggable(false).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
}
