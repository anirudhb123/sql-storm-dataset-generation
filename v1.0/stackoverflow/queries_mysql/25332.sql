
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Tags t ON FIND_IN_SET(t.Id, SUBSTRING(REPLACE(REPLACE(p.Tags, '[',''),']',''),'"','') FROM ',')  
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.CreationDate
    HAVING 
        COUNT(DISTINCT c.Id) > 5  
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.TagList
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(tv.TagList, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS PostCount,
        AVG(tg.Count) AS AverageUsage,
        MAX(tg.Count) AS MaxUsage
    FROM 
        TopPosts tv
    JOIN 
        Tags tg ON tg.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(tv.TagList, ',', numbers.n), ',', -1)
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(tv.TagList) - CHAR_LENGTH(REPLACE(tv.TagList, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AverageUsage,
    ts.MaxUsage,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    SUM(rp.Score) AS TotalScore
FROM 
    TagStatistics ts
JOIN 
    RankedPosts rp ON FIND_IN_SET(ts.TagName, rp.TagList)
GROUP BY 
    ts.TagName, ts.PostCount, ts.AverageUsage, ts.MaxUsage
ORDER BY 
    ts.PostCount DESC, 
    TotalScore DESC
LIMIT 20;
