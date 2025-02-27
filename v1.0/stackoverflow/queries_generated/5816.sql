WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostsCount,
        CommentsCount,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation
    FROM 
        UserScore
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.UpVotes,
    u.DownVotes,
    u.PostsCount,
    u.CommentsCount,
    t.Title,
    p.CreationDate,
    p.Score
FROM 
    TopUsers u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
JOIN 
    (SELECT 
        PostId, Title
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Question
    ORDER BY 
        CreationDate DESC
    LIMIT 10) AS t ON p.Id = t.PostId
WHERE 
    u.RankByReputation <= 10
ORDER BY 
    u.RankByReputation;
