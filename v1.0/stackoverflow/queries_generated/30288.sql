WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        1 AS Level
    FROM Users u
    WHERE u.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Id = ur.UserId
    WHERE ur.Level < 5 AND u.Reputation > ur.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(v.VoteTypeId = 10) AS DeletionVotes,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        Title,
        CommentCount,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM PostAnalytics
)
SELECT 
    u.DisplayName AS TopUser,
    u.Reputation,
    pp.Title AS MostCommentedTitle,
    pp.CommentCount
FROM TopUsers u
LEFT JOIN MostCommentedPosts pp ON pp.CommentRank = 1
WHERE u.Rank <= 10
ORDER BY u.Reputation DESC
OPTION (MAXRECURSION 10);
