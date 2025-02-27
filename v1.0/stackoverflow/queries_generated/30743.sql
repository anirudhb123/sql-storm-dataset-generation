WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
    ),
    PopularTags AS (
        SELECT 
            t.TagName,
            COUNT(pt.PostId) AS TagCount
        FROM 
            Tags t
            JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, '::'))
            JOIN PostHistory ph ON ph.PostId = p.Id
        WHERE 
            ph.CreationDate >= NOW() - INTERVAL '1 year'
        GROUP BY 
            t.TagName
        ORDER BY 
            TagCount DESC
        LIMIT 10
    )
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.CreationDate,
    pt.TagName,
    pt.TagCount,
    CASE 
        WHEN rp.Score >= 100 THEN 'Very Active'
        WHEN rp.Score >= 50 THEN 'Active'
        WHEN rp.Score >= 10 THEN 'Moderate'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    RankedPosts rp
    JOIN PopularTags pt ON rp.RankScore <= 10
WHERE 
    rp.CommentTotal > 0
    AND rp.ViewCount IS NOT NULL
ORDER BY 
    rp.Score DESC,
    rp.CommentCount DESC;

-- Optional Benchmark: Aggregate statistics
SELECT 
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.AnswerCount) AS TotalAnswers
FROM 
    RankedPosts rp
WHERE 
    rp.RankScore <= 5;  -- For top 5 posts only
