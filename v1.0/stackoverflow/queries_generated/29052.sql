WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        t.TagName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankedByScore,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.CreationDate ASC) AS RankedByDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName) AS t 
    ON true
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName, t.TagName
),
AggregatedResults AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews,
        SUM(CommentCount) AS TotalComments,
        MIN(RankedByScore) AS BestPostRankByScore,
        MIN(RankedByDate) AS FirstPostRankByDate
    FROM 
        RankedPosts
    GROUP BY 
        TagName
)
SELECT 
    a.TagName,
    a.PostCount,
    a.AverageScore,
    a.TotalViews,
    a.TotalComments,
    CASE 
        WHEN a.BestPostRankByScore = 1 THEN 'Top Ranked'
        ELSE 'Not Top Ranked' 
    END AS PostRankStatus,
    CASE 
        WHEN a.FirstPostRankByDate <= NOW() - INTERVAL '1 year' THEN 'Oldest Post Over 1 Year Ago'
        ELSE 'Recent Posts'
    END AS PostAgeStatus
FROM 
    AggregatedResults a
ORDER BY 
    a.PostCount DESC, a.AverageScore DESC;
