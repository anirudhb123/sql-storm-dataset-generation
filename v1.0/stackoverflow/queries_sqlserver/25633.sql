
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
        STRING_AGG(c.Text, '; ') AS Comments
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
        ISNULL(cs.CommentCount, 0) AS CommentCount,
        ISNULL(cs.Comments, '') AS Comments,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM TopQuestions tq
    LEFT JOIN CommentStatistics cs ON tq.PostId = cs.PostId
    CROSS APPLY (
        SELECT 
            VALUE AS TagName
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') 
        WHERE p.Id = tq.PostId
    ) t 
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
