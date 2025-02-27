
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    JOIN 
        (SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
             UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS t
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, t.TagName
),
TopPosts AS (
    SELECT 
        TagName, 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.TagName, 
    COUNT(tp.PostId) AS TopPostCount, 
    AVG(tp.Score) AS AverageScore, 
    SUM(tp.ViewCount) AS TotalViews
FROM 
    TopPosts tp
GROUP BY 
    tp.TagName
ORDER BY 
    AverageScore DESC;
