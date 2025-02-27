WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        COUNT(DISTINCT p.Id) AS RelatedClosedPosts
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened posts
    GROUP BY 
        ph.PostId, ph.Title
)
SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle,
    ph.Level AS HierarchyLevel,
    ur.DisplayName AS Author,
    ur.Reputation AS AuthorReputation,
    COALESCE(clp.RelatedClosedPosts, 0) AS RelatedClosedPostsCount,
    p.ViewCount,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
JOIN 
    Users ur ON p.OwnerUserId = ur.Id
LEFT JOIN 
    ClosedPosts clp ON p.Id = clp.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, '<>') AS t
GROUP BY 
    p.Id, p.Title, ph.Level, ur.DisplayName, ur.Reputation, clp.RelatedClosedPosts
ORDER BY 
    p.ViewCount DESC, ur.Reputation DESC;
