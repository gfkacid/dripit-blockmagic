export const getWinningBattle = async (
  battleIdFirst: number,
  battleIdSecond: number
) => {
  return battleIdFirst % 2;
};
