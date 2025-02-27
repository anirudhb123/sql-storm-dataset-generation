
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagList,
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
        Tags t ON t.Id IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), ','))
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.CreationDate
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
        value AS TagName,
        COUNT(*) AS PostCount,
        AVG(tg.Count) AS AverageUsage,
        MAX(tg.Count) AS MaxUsage
    FROM 
        TopPosts tv
    JOIN 
        Tags tg ON tg.TagName IN (SELECT value FROM STRING_SPLIT(tv.TagList, ','))
    GROUP BY 
        value
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
    RankedPosts rp ON ts.TagName IN (SELECT value FROM STRING_SPLIT(rp.TagList, ','))
GROUP BY 
    ts.TagName, ts.PostCount, ts.AverageUsage, ts.MaxUsage
ORDER BY 
    ts.PostCount DESC, 
    TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
