
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT TRIM(TRAILING '>' FROM TRIM(LEADING '<' FROM tag_name)) AS tag_name 
         FROM (
             SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name 
             FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                   UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
             WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
         ) AS tag_names
        ) AS tag_name ON TRUE
    JOIN 
        Tags t ON t.TagName = tag_name.tag_name
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.AnswerCount > 0
)

SELECT 
    fp.Id,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.Tags,
    fp.Upvotes,
    fp.Downvotes,
    ROUND(COALESCE(fp.Upvotes / NULLIF(fp.Upvotes + fp.Downvotes, 0), 0), 2) AS UpvoteRatio
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10 
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
