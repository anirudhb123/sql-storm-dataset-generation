
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId IN (1, 2) 
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        AnswerCount,
        ViewCount,
        OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 5 
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS Tag
    FROM Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE p.Tags IS NOT NULL
),
PostCommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        AVG(Score) AS AvgCommentScore
    FROM Comments
    GROUP BY PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.AnswerCount,
    fp.ViewCount,
    fp.OwnerDisplayName,
    pt.Tag,
    COALESCE(pcs.CommentCount, 0) AS CommentCount,
    COALESCE(pcs.AvgCommentScore, 0) AS AvgCommentScore
FROM FilteredPosts fp
LEFT JOIN PostTags pt ON fp.PostId = pt.PostId
LEFT JOIN PostCommentStats pcs ON fp.PostId = pcs.PostId
ORDER BY fp.PostId, pt.Tag;
