
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
    CROSS JOIN 
        (SELECT DISTINCT TRIM(REGEXP_SUBSTR(p.Tags, '[^,]+', 1, seq)) AS TagName
         FROM 
           (SELECT ROW_NUMBER() OVER () AS seq FROM TABLE(generator(rowcount => 100))) seq
         WHERE 
           seq <= REGEXP_COUNT(p.Tags, ',') + 1) AS t
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
