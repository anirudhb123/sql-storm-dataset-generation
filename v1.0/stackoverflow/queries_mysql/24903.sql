
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        @row_num := IF(@prev_post_type = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p INNER JOIN 
         (SELECT a.N + b.N * 10 + 1 n FROM 
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
        ) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON tag = t.TagName,
        (SELECT @row_num := 0, @prev_post_type := NULL) AS r
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.CommentCount,
        CASE 
            WHEN rp.CommentCount = 0 THEN 'No comments'
            WHEN rp.CommentCount < 5 THEN 'Less than 5 comments'
            ELSE 'More than 5 comments'
        END AS CommentSummary,
        CASE 
            WHEN rp.Score IS NULL THEN 'No score'
            WHEN rp.Score > 10 THEN 'High score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium score'
            ELSE 'Low score'
        END AS ScoreCategory,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.CommentSummary,
    fp.ScoreCategory,
    fp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, fp.CommentCount, 
    fp.CommentSummary, fp.ScoreCategory, fp.Tags, u.DisplayName, u.Reputation
ORDER BY 
    fp.ViewCount DESC, fp.CommentCount DESC;
