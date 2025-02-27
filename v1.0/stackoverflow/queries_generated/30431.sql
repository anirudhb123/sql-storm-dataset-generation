WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start with top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1
                         WHEN v.VoteTypeId = 3 THEN -1 
                         ELSE 0 END), 0) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Only consider posts from the last year
    GROUP BY 
        p.Id, p.Title
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.TotalScore,
        ps.CommentCount,
        RANK() OVER (ORDER BY ps.TotalScore DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostScores ps
    WHERE 
        ps.TotalScore > 0
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    CASE 
        WHEN p.CreationDate < NOW() - INTERVAL '30 DAY' THEN 'Old Post'
        ELSE 'New Post'
    END AS PostAgeCategory,
    pt.Name AS PostTypeName,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1  -- Gold badge
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS TagArray 
LEFT JOIN 
    LATERAL (SELECT TagName FROM Tags WHERE Id IN (SELECT UNNEST(TagArray))) AS t
INNER JOIN 
    FilteredPosts f ON p.Id = f.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId  -- Joining to get post hierarchy
GROUP BY 
    p.Id, p.Title, p.Score, p.AnswerCount, p.CommentCount, pt.Name, b.Name
HAVING 
    COUNT(DISTINCT u.Id) > 1  -- Only return posts with more than one unique user 
ORDER BY 
    f.Rank
LIMIT 100;  -- Limit to top 100 ranked posts
