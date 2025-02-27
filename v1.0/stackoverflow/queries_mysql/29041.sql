
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS tag
         FROM 
             (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         CROSS JOIN 
             Posts p
         WHERE 
             CHAR_LENGTH(p.Tags) > 2) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        TagsArray
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
)
SELECT 
    tp.OwnerDisplayName,
    COUNT(DISTINCT tp.PostId) AS PostCount,
    SUM(tp.ViewCount) AS TotalViews,
    SUM(tp.Score) AS TotalScore,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS AllTags
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.TagsArray, ',', n.n), ',', -1)) AS TagName
     FROM 
         (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
     CROSS JOIN 
         TopPosts tp) AS t ON TRUE
GROUP BY 
    tp.OwnerDisplayName
ORDER BY 
    TotalScore DESC, TotalViews DESC;
