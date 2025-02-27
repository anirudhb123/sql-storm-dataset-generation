
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        p.Score,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_owner := NULL) AS r
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.Score, p.OwnerUserId
),

PostTagCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
        FROM Posts p 
        CROSS JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
        WHERE n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1)) ) AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_names.TagName
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Score,
    COALESCE(pt.TagCount, 0) AS UniqueTagCount,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTagCount pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank = 1  
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC
LIMIT 10;
