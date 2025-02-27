
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
        p.PostTypeId = 1  
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
    AVG(CASE WHEN r.Depth = 0 THEN r.Score ELSE NULL END) AS AvgScoreForQuestions,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(r.CreationDate) AS LastPostDate
FROM 
    RecursivePosts r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
OUTER APPLY (
    SELECT 
        value AS TagName
    FROM 
        STRING_SPLIT(p.TAGS, '<>') 
    WHERE 
        p.Id = r.PostId AND p.TAGS IS NOT NULL
) t 
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    QuestionCount DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
