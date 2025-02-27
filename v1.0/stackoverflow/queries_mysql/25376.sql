
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        OwnerDisplayName
    FROM
        RankedPosts
    WHERE
        Rank <= 5 
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    GROUP BY
        c.PostId
),
PostScores AS (
    SELECT
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.CreationDate,
        fp.Score,
        fp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM
        FilteredPosts fp
    LEFT JOIN
        PostComments pc ON fp.PostId = pc.PostId
),
PostTags AS (
    SELECT
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><', numbers.n), '><', -1) AS Tag
    FROM
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2)) - CHAR_LENGTH(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><', '')) >= numbers.n - 1
    WHERE
        p.PostTypeId = 1 
)
SELECT
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    pt.Tag,
    CASE
        WHEN ps.Score >= 100 THEN 'High Score'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM
    PostScores ps
JOIN
    PostTags pt ON ps.PostId = pt.PostId
ORDER BY
    ps.Score DESC, ps.CreationDate DESC;
