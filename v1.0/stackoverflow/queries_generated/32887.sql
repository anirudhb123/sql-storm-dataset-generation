WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.Score,
        p2.OwnerUserId,
        p2.PostTypeId,
        Level + 1
    FROM 
        Posts p1
    JOIN 
        Posts p2 ON p1.Id = p2.ParentId
    WHERE 
        p1.PostTypeId = 1 -- Linking Answers to Questions
), TagPostCTE AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        COUNT(ph.Id) OVER (PARTITION BY t.Id) AS EditCount -- Count of history edits per tag
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        (p.LastEditDate IS NOT NULL AND p.LastEditDate > CURRENT_DATE - INTERVAL '1 year')
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    t.TagName,
    COUNT(DISTINCT tp.PostId) AS PostCount,
    SUM(tp.EditCount) AS TotalEdits,
    AVG(tp.EditCount) AS AvgEditsPerPost,
    COUNT(DISTINCT CASE WHEN r.Level = 2 THEN r.Id END) AS AnswerCount
FROM 
    Users u
JOIN 
    RecursivePostCTE r ON u.Id = r.OwnerUserId
JOIN 
    TagPostCTE tp ON r.Id = tp.PostId
JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
WHERE 
    u.Reputation > 1000 -- Filter users with reputation over 1000
GROUP BY 
    u.DisplayName, u.Reputation, t.TagName
HAVING 
    SUM(tp.EditCount) > 10 -- Users need to have edited more than 10 times
ORDER BY 
    TotalEdits DESC, UserName;
