
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
        value AS Tag
    FROM Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS Tag
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
    ISNULL(pcs.CommentCount, 0) AS CommentCount,
    ISNULL(pcs.AvgCommentScore, 0) AS AvgCommentScore
FROM FilteredPosts fp
LEFT JOIN PostTags pt ON fp.PostId = pt.PostId
LEFT JOIN PostCommentStats pcs ON fp.PostId = pcs.PostId
ORDER BY fp.PostId, pt.Tag;
