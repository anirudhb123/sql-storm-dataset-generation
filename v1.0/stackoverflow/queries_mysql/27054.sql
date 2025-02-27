
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        @row_number := IF(@prev_partition = CASE 
            WHEN p.Score > 10 THEN 'High Score'
            WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score' END, @row_number + 1, 1) AS Rank,
        @prev_partition := CASE 
            WHEN p.Score > 10 THEN 'High Score'
            WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score' END
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT @row_number := 0, @prev_partition := '') AS vars
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
        AND p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        Score,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostTagMetrics AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
         FROM 
            (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1, 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2, 
            (SELECT @row := 0) t3) n
         WHERE n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) / 2) AS tag_names
    ) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.Score,
    ptm.Tags,
    fp.CreationDate
FROM 
    FilteredPosts fp
JOIN 
    PostTagMetrics ptm ON fp.Id = ptm.PostId
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
