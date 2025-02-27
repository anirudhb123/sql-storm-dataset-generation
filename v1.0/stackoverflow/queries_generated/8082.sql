WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes
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
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
) 
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.PostCount, 
    tu.AnswerCount, 
    tu.UpVotes, 
    tu.DownVotes, 
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges, 
    COALESCE(SUM(b.Class = 2), 0) AS SilverBadges, 
    COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
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
