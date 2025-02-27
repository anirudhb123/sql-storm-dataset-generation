-- Performance Benchmarking for StackOverflow Schema
-- This query retrieves various statistics to measure performance

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(v.CreationDate) AS LastVoteDate,
        MAX(h.CreationDate) AS LastHistoryDate,
        MAX(p.CreationDate) AS PostCreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, pt.Name
)

SELECT 
    PostType,
    COUNT(*) AS TotalPosts,
    AVG(CommentCount) AS AvgComments,
    AVG(VoteCount) AS AvgVotes,
    AVG(BadgeCount) AS AvgBadges,
    MAX(LastVoteDate) AS LastVoteDate,
    MAX(LastHistoryDate) AS LastHistoryDate,
    MAX(PostCreationDate) AS MostRecentPost
FROM 
    PostStats
GROUP BY 
    PostType
ORDER BY 
    TotalPosts DESC;
