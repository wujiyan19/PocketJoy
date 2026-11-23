import { ExpansionArt } from '../../common/ExpansionArt';
import { GameBoardArt } from '../../components/GameBoardArt';

@Builder
export function ExpansionBackdrop(gameId: string) {
  GameBoardArt(ExpansionArt.board(gameId))
}
