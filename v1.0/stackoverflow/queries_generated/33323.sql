WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
), 

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId * CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(v.VoteTypeId * CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 

FeaturedPosts AS (
    SELECT 
        ph.PostId,
        p.Title,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, p.Title
    HAVING 
        COUNT(DISTINCT ph.Id) > 5
)

SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.Upvotes,
    ua.Downvotes,
    COUNT(DISTINCT fp.PostId) AS FeaturedPostsCount,
    ARRAY_AGG(DISTINCT fp.Title) AS FeaturedPostTitles,
    RANK() OVER (ORDER BY ua.Upvotes DESC) AS UserRank,
    COALESCE((SELECT 
        COUNT(DISTINCT v2.PostId) 
    FROM 
        Votes v2 
    WHERE 
        v2.UserId = ua.UserId 
        AND v2.CreationDate > CURRENT_DATE - INTERVAL '1 month'), 0) AS RecentVotes
FROM 
    UserActivity ua
LEFT JOIN 
    FeaturedPosts fp ON ua.UserId = fp.PostId
GROUP BY 
    ua.UserId, ua.DisplayName
ORDER BY 
    ua.Upvotes DESC;
