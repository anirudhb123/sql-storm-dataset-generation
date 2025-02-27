WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.Score,
        a.OwnerUserId,
        a.PostTypeId,
        a.CreationDate,
        rp.Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursivePosts rp ON q.Id = rp.PostId
)
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT r.PostId) AS QuestionCount,
    SUM(r.Score) AS TotalScore,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    AVG(
        CASE 
            WHEN r.Depth = 0 THEN r.Score 
            ELSE NULL 
        END
    ) AS AvgScoreForQuestions,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    RecursivePosts r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(r.TAGS, '<>')) AS TagName
        FROM 
            Posts AS p
        WHERE 
            p.Id = r.PostId AND p.TAGS IS NOT NULL
    ) t ON TRUE
GROUP BY 
    u.Id
ORDER BY 
    QuestionCount DESC
LIMIT 10
OFFSET 5;

WITH PostHistoryCTE AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5)  -- Edit title or body
)
SELECT 
    u.DisplayName,
    p.Title,
    ph.Comment AS EditComment,
    ph.CreationDate AS EditDate,
    CASE 
        WHEN ph.RecentEdit = 1 THEN 'Most Recent Edit'
        ELSE NULL 
    END AS EditStatus
FROM 
    PostHistoryCTE ph
JOIN 
    Users u ON ph.UserId = u.Id
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.RecentEdit = 1 OR ph.Comment IS NOT NULL
ORDER BY 
    ph.CreationDate DESC;

-- Summary of Posts and tags
SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT t.Id) AS TotalTags,
    STRING_AGG(DISTINCT tp.TagName, ', ') AS AllTags
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, '<>')) AS TagName
    ) tp ON TRUE
LEFT JOIN 
    Tags t ON tp.TagName = t.TagName
GROUP BY 
    pt.Id
ORDER BY 
    TotalPosts DESC;
