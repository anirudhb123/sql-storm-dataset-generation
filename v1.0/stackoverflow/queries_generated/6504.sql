WITH UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount,
        SUM(V.Score) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserID,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        Wikis,
        BadgesCount,
        TotalVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    u.*,
    ROW_NUMBER() OVER (PARTITION BY Rank ORDER BY TotalVotes DESC) AS VoteRank
FROM 
    TopUsers u
WHERE 
    Rank <= 10
ORDER BY 
    Rank, VoteRank;
