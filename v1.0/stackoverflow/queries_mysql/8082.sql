
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes, 
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
) 
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.PostCount, 
    tu.AnswerCount, 
    tu.UpVotes, 
    tu.DownVotes, 
    COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges, 
    COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges, 
    COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, tu.AnswerCount, tu.UpVotes, tu.DownVotes
ORDER BY 
    tu.Rank;
