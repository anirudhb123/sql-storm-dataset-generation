
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag_name
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_name 
    JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.AnswerCount, p.CommentCount
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.LastAccessDate DESC) AS Rank
    FROM 
        Users u
),
RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text,
        c.CreationDate,
        c.UserId,
        u.DisplayName AS UserDisplayName,
        ROW_NUMBER() OVER (ORDER BY c.CreationDate DESC) AS Rank
    FROM 
        Comments c
    JOIN 
        Users u ON c.UserId = u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    ru.UserId AS RecentUserId,
    ru.DisplayName AS RecentUserName,
    ru.Reputation AS RecentUserReputation,
    rc.CommentId,
    rc.Text AS RecentCommentText,
    rc.CreationDate AS RecentCommentDate
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentUsers ru ON ru.Rank <= 10
LEFT JOIN 
    RecentComments rc ON rc.PostId = rp.PostId AND rc.Rank <= 5
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.ViewCount DESC, rc.CreationDate DESC;
