
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCountDistinct,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, 
        p.CommentCount, p.FavoriteCount, u.Reputation
),
TagMetrics AS (
    SELECT 
        t.TagName,
        SUM(pm.ViewCount) AS TotalViewCount,
        AVG(pm.Score) AS AverageScore,
        SUM(pm.AnswerCount) AS TotalAnswerCount
    FROM 
        PostMetrics pm
    JOIN 
        Posts p ON pm.PostId = p.Id
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag 
        ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.TagName
    GROUP BY 
        t.TagName
)
SELECT 
    tm.TagName,
    tm.TotalViewCount,
    tm.AverageScore,
    tm.TotalAnswerCount
FROM 
    TagMetrics tm
ORDER BY 
    tm.TotalViewCount DESC
LIMIT 10;
