WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        PostTypeId,
        ParentId,
        Title,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.PostTypeId,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.TotalCommentScore,
    u.VoteCount,
    th.TagName,
    th.PostCount AS TagPostCount,
    th.TotalViews,
    th.AverageScore,
    ph.Level
FROM 
    UserActivity u
CROSS JOIN 
    TagStats th
LEFT JOIN 
    PostHierarchy ph ON u.PostCount > 0
WHERE 
    u.TotalCommentScore > 100
    AND th.AverageScore >= 10
ORDER BY 
    u.VoteCount DESC, 
    th.TotalViews DESC;

