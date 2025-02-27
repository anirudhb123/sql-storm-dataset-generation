-- Performance benchmarking query for Stack Overflow schema

-- Benchmarking the number of Posts, Users, and average Vote counts
WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUniqueUsers
    FROM 
        Posts
),
UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
AvgVoteCount AS (
    SELECT 
        AVG(VoteCount) AS AverageVotesPerUser
    FROM 
        UserVoteCounts
)

SELECT 
    pc.TotalPosts,
    pc.TotalUniqueUsers,
    av.AverageVotesPerUser
FROM 
    PostCounts pc,
    AvgVoteCount av;

-- Benchmarking PostHistory edits by type
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS EditCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    EditCount DESC;

-- Benchmarking the most active users based on number of posts and comments
WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserCommentCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(upc.PostCount, 0) AS PostCount,
    COALESCE(ucc.CommentCount, 0) AS CommentCount,
    (COALESCE(upc.PostCount, 0) + COALESCE(ucc.CommentCount, 0)) AS TotalActivity
FROM 
    Users u
LEFT JOIN 
    UserPostCounts upc ON u.Id = upc.OwnerUserId
LEFT JOIN 
    UserCommentCounts ucc ON u.Id = ucc.UserId
ORDER BY 
    TotalActivity DESC
LIMIT 10;  -- Top 10 most active users

-- Benchmarking average view counts of posts by type
SELECT 
    pt.Name AS PostType,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageViewCount DESC;
