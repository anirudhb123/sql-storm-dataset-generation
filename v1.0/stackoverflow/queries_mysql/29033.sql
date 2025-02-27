
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS TagName
         FROM (SELECT @row:=@row+1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
         SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t1,
         (SELECT @row:=0) t2) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) t
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        TagName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3 
),
PostStats AS (
    SELECT 
        tp.TagName,
        COUNT(tp.PostId) AS PostCount,
        AVG(tp.Score) AS AvgScore,
        SUM(tp.ViewCount) AS TotalViews
    FROM 
        TopPosts tp
    GROUP BY 
        tp.TagName
)
SELECT 
    ps.TagName,
    ps.PostCount,
    ps.AvgScore,
    ps.TotalViews,
    p.PostId,
    p.Title,
    p.CreationDate
FROM 
    PostStats ps
JOIN 
    TopPosts p ON ps.TagName = p.TagName
ORDER BY 
    ps.AvgScore DESC, ps.PostCount DESC;
