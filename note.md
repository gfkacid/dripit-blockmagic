First of all, backend api are live on http://46.10.214.242:3000/ . For example: http://46.10.214.242:3000/users

Reason for hosting them on local server instead vercel if first because on vercel it will be difficult setting up the mysql server, secondly because this way i can reflect changes live without need to redeploy, restart, pull git changes, etc.

Apart from this, the battles/resolve-battle endpoint is up and running. Because @acid haven't provided real data feed for the battles table yet, i did imported 5 random entries and mocked the api to return entry id % 2, which will always return 0 or 1 depending of the id called. if you call for bigger id let's say 7, you will get 404 not found.

This way i am also saving the limited api calls on the key we have. i have implemented the call in separate function ready to be put when real data is available.

at some point today i will also put live the battles/resolve-battles-bulk

PANCAKESWAP

How is the payout calculated?
Payout Ratio for UP Pool = Total Value of Both Pools ÷ Value of UP Pool

Payout Ratio for DOWN Pool = Total Value of Both Pools ÷ Value of DOWN Pool

For example, if there’s 15 BNB in the DOWN side of a round, and the overall prize pool is 150 BNB, the DOWN payout ratio will be (150/15) = 10x.

Payout Amount = Payout Ratio × Position × (1 - Treasury Fee)

In the above case, if the round ends on a DOWN result, if you committed 2 BNB to a DOWN position, you’d get a payout of (2\*10) × (1-0.03) = 19.4 BNB. Your profit would be 17.4 BNB (19.4 - 2).

The treasury fee is currently set at 3%: this may be subject to changes, which would be announced on PancakeSwap’s official communication channels. Treasury fees are used to buy back and burn CAKE tokens.

What are the fees?
3% of each round's total pot will go to the treasury, of which a portion will be used to buyback and burn CAKE burn every Monday.
