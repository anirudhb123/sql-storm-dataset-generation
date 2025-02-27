
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 10 
),
CommentStatistics AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(c.Text SEPARATOR '; ') AS Comments
    FROM Comments c
    JOIN TopQuestions tq ON c.PostId = tq.PostId
    GROUP BY c.PostId
),
TaggedQuestions AS (
    SELECT
        tq.PostId,
        tq.Title,
        tq.CreationDate,
        tq.Score,
        tq.ViewCount,
        tq.OwnerDisplayName,
        cs.CommentCount,
        cs.Comments,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM TopQuestions tq
    LEFT JOIN CommentStatistics cs ON tq.PostId = cs.PostId
    LEFT JOIN (
        SELECT 
            p.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM Posts p
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON tq.PostId = t.PostId
    GROUP BY tq.PostId, tq.Title, tq.CreationDate, tq.Score, tq.ViewCount, tq.OwnerDisplayName, cs.CommentCount, cs.Comments
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    Comments,
    Tags
FROM TaggedQuestions
ORDER BY Score DESC, ViewCount DESC;
