WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        LastAccessDate,
        DisplayName,
        1 AS Level
    FROM Users
    WHERE Reputation > 0  -- Start with users having positive reputation
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.DisplayName,
        Level + 1
    FROM Users u
    JOIN UserReputationCTE ur ON u.Reputation = ur.Reputation - 10 -- Decrease by 10 for analysis
    WHERE Level < 10  -- Stop after 10 levels
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate, 
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
HighScoringPosts AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.CreationDate,
        pwc.Score,
        pwc.ViewCount,
        pwc.CommentCount,
        pwc.LastCommentDate,
        ROW_NUMBER() OVER (PARTITION BY pwc.PostId ORDER BY pwc.Score DESC) AS Rnk
    FROM PostWithComments pwc
    WHERE pwc.Score > 10
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(p.Id) > 5
)
SELECT 
    u.DisplayName,
    u.Reputation,
    hp.Title AS HighScoringPostTitle,
    hp.Score AS HighScoringPostScore,
    hp.ViewCount AS HighScoringPostViews,
    hp.CommentCount AS HighScoringPostComments,
    ur.Level AS UserReputationLevel,
    hp.LastCommentDate,
    COALESCE(ba.Name, 'None') AS BadgeName
FROM TopUsers u
JOIN HighScoringPosts hp ON u.UserId = hp.PostId
LEFT JOIN Badges ba ON ba.UserId = u.UserId
JOIN UserReputationCTE ur ON ur.Id = u.UserId
WHERE ur.Level <= 5 
ORDER BY u.Reputation DESC, hp.Score DESC;
This SQL query involves complex constructs including recursive CTEs, outer joins, grouping, and window functions to generate a report that highlights top users based on their reputation, along with their high-scoring posts and any associated badges. It systematically breaks down the user reputation levels and analyzes the comments and scores of posts, producing a comprehensive snapshot of engagement and activity on the platform.
