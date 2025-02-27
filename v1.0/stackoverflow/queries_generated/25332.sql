WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList,
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
        Tags t ON t.Id = ANY(substring(p.Tags FROM '\\[(.*?)\\]')::int[])  -- Assuming Tags are stored in a specific format
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.CreationDate
    HAVING 
        COUNT(DISTINCT c.Id) > 5  -- Having more than 5 comments
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
        rp.Rank <= 10  -- Top 10 ranked questions
),
TagStatistics AS (
    SELECT 
        unnest(tv.TagList) AS TagName,
        COUNT(*) AS PostCount,
        AVG(tg.Count) AS AverageUsage,
        MAX(tg.Count) AS MaxUsage
    FROM 
        TopPosts tv
    JOIN 
        Tags tg ON tg.TagName = ANY(tv.TagList)
    GROUP BY 
        tv.TagList
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
    RankedPosts rp ON ts.TagName = ANY(rp.TagList)
GROUP BY 
    ts.TagName, ts.PostCount, ts.AverageUsage, ts.MaxUsage
ORDER BY 
    ts.PostCount DESC, 
    TotalScore DESC
LIMIT 20;
