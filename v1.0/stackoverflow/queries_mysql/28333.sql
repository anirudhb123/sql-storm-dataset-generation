
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpvoteCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        (SELECT TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1))) AS tag
         FROM (SELECT @row := @row + 1 AS n
               FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
                     (SELECT @row := 0) AS init) numbers 
         WHERE @row < CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) 
        ) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Score
),
BenchmarkResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.TagList,
        @row_number := @row_number + 1 AS Rank
    FROM 
        RankedPosts rp, (SELECT @row_number := 0) AS init
    ORDER BY 
        rp.Score DESC, rp.CommentCount DESC
)
SELECT 
    br.Rank,
    br.PostId,
    br.Title,
    br.OwnerDisplayName,
    br.CreationDate,
    br.Score,
    br.CommentCount,
    br.UpvoteCount,
    br.TagList
FROM 
    BenchmarkResults br
WHERE 
    br.Score > 10  
ORDER BY 
    br.Rank
LIMIT 10;
