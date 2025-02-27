
WITH TagAnalysis AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation,
        GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS UserNames
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
)
SELECT 
    ta.TagName,
    ta.PostCount,
    ta.QuestionCount,
    ta.AnswerCount,
    ta.AvgReputation,
    ta.UserNames,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerName
FROM 
    TagAnalysis ta
LEFT JOIN 
    RecentPosts rp ON rp.Title LIKE CONCAT('%', ta.TagName, '%')
ORDER BY 
    ta.PostCount DESC, 
    rp.CreationDate DESC
LIMIT 10;
