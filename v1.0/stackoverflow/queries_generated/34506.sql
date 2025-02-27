WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId, 
        Title, 
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT Id, UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName FROM Posts) t ON p.Id = t.Id
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    ua.PostsCreated,
    ua.TotalScore,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    COUNT(DISTINCT p.Id) AS AnswerCount,
    MAX(p.ViewCount) AS MaxViewCount,
    STRING_AGG(DISTINCT pt.Tags, '; ') AS AllTags,
    SUM(p.Score) AS OverallScore,
    COUNT(c.Id) AS CommentsCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
    COALESCE(SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END), 0) AS ClosedPostsCount,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
WHERE 
    ua.TotalScore > 100
GROUP BY 
    u.DisplayName, ua.PostsCreated, ua.TotalScore, ua.TotalUpvotes, ua.TotalDownvotes
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    OverallScore DESC;
