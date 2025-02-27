WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Top-level questions
    UNION ALL
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.CreationDate,
        p2.ViewCount,
        p2.Score,
        p2.ParentId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
    WHERE 
        p2.PostTypeId = 2  -- Answers
),
PostViewCounts AS (
    SELECT 
        ph.PostId, 
        SUM(ph.ViewCount) AS TotalViewCount,
        COUNT(CASE WHEN ph.Level = 1 THEN 1 END) AS AnswerCount,
        MAX(ph.CreationDate) AS LatestActivity
    FROM 
        RecursivePostHierarchy ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Title,
    p.TotalViewCount,
    pb.AnswerCount,
    u.DisplayName,
    ub.BadgeCount,
    ub.LastBadgeDate
FROM 
    PostViewCounts p
JOIN 
    Users u ON p.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    Posts pb ON p.PostId = pb.Id
WHERE 
    p.TotalViewCount > 100 -- Filter only popular posts
ORDER BY 
    p.TotalViewCount DESC, 
    pb.AnswerCount DESC
LIMIT 10;


In this query:

1. **Recursive CTE (`RecursivePostHierarchy`)** gathers posts and their answers in a hierarchy, using a union to combine questions and their related answers.

2. **CTE (`PostViewCounts`)** summarizes view counts and answer counts for each post.

3. **CTE (`UserBadges`)** counts badges held by users and notes when they last acquired one.

4. The main `SELECT` statement joins these CTEs to fetch titles, view counts, user information, and badge metrics for popular posts with a view count over 100, ordered by views and answer counts. 

This complex query showcases various SQL constructs such as CTEs, joins, aggregations, filtering, and ordering.
