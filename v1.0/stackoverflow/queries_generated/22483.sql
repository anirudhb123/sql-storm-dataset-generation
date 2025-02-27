WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 -- Only active users
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotesCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' -- Recent posts
)
SELECT 
    ua.DisplayName,
    SUM(ua.UpVotes) AS TotalUpVotes,
    SUM(ua.DownVotes) AS TotalDownVotes,
    COUNT(DISTINCT pm.PostId) AS UniquePosts,
    SUM(pm.ViewCount) AS TotalViews,
    AVG(pm.CommentCount) AS AvgCommentsPerPost,
    MAX(pm.PostRank) AS HighestPostRank,
    COALESCE(MIN(pm.CreationDate), 'No Posts') AS EarliestPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    PostMetrics pm ON ua.UserId = pm.OwnerUserId
GROUP BY 
    ua.DisplayName
HAVING 
    SUM(ua.UpVotes) - SUM(ua.DownVotes) > 10 -- Only users with a positive vote balance
ORDER BY 
    SUM(ua.UpVotes) DESC, TotalViews DESC;

-- A bizarre edge case is being tested for NULL logic and performance:
WITH NULLCheck AS (
    SELECT 
        CASE 
            WHEN p.Id IS NOT NULL THEN 'Post Exists'
            ELSE 'Post Does Not Exist'
        END AS PostExistence,
        COUNT(*) AS Count
    FROM 
        Posts p
    FULL OUTER JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        PostExistence
)
SELECT 
    PostExistence,
    Count,
    CASE 
        WHEN COUNT > 100 THEN 'Heavy Load'
        ELSE 'Normal Load'
    END AS LoadStatus
FROM 
    NULLCheck;
