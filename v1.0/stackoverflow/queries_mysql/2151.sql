
WITH UserStat AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        PositivePosts, 
        NegativePosts, 
        UpVotes, 
        DownVotes,
        @rank := IF(@prev_reputation = Reputation, @rank + 1, 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserStat, (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY 
        Reputation DESC
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS Owner,
        @score_rank := IF(@prev_score = p.Score AND @prev_viewcount = p.ViewCount, @score_rank + 1, 1) AS ScoreRank,
        @prev_score := p.Score,
        @prev_viewcount := p.ViewCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1, (SELECT @score_rank := 0, @prev_score := NULL, @prev_viewcount := NULL) s
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
)
SELECT 
    tu.DisplayName AS UserName,
    tu.Reputation,
    tu.PostCount,
    tu.PositivePosts,
    tu.NegativePosts,
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount
FROM 
    TopUsers tu
LEFT JOIN 
    PopularPosts pp ON tu.PostCount > 0 
WHERE 
    tu.ReputationRank <= 10
    AND (pp.Score > 10 OR pp.ViewCount > 1000)
ORDER BY 
    tu.Reputation DESC, pp.Score DESC;
