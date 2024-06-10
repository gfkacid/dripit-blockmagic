import { useState, useEffect } from "react";
import { getBattles } from "../../lib/api/getBattles";
import { BattleComponent } from "../../components";
import { Battle } from "../../lib/types/Battle.type";

const Battles = () => {
  const [battles, setBattles] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchBattles = async () => {
      const response = await getBattles();
      setBattles(response.data);
      setLoading(false);
    };

    fetchBattles();
  }, []);

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <h1>Battles</h1>
      {battles.map((battle: Battle) => (
        <BattleComponent key={battle.id} battle={battle} />
      ))}
    </div>
  );
};

export default Battles;
