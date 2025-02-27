
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1 AS TagCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.TagCount,
        rp.Score,
        rp.CommentCount,
        rp.CreationDate,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CreationDate DESC) AS Rank
    FROM 
        RankedPosts rp
),
TaggedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.TagCount,
        pd.Score,
        pd.CommentCount,
        pd.CreationDate,
        pd.Rank,
        t.TagName
    FROM 
        PostDetails pd
    JOIN 
        Posts p ON pd.PostId = p.Id
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t 
         ON t.TagName = t.TagName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.TagCount,
    tp.Score,
    tp.CommentCount,
    tp.Rank,
    GROUP_CONCAT(DISTINCT tp.TagName ORDER BY tp.TagName ASC SEPARATOR ', ') AS Tags
FROM 
    TaggedPosts tp
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.TagCount, tp.Score, tp.CommentCount, tp.Rank
ORDER BY 
    tp.Rank
LIMIT 10;
