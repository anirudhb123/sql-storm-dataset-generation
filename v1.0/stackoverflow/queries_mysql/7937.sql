
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR AND
        p.Score >= 5
), AggregatedData AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS PostCount,
        AVG(rp.Score) AS AvgScore,
        AVG(rp.ViewCount) AS AvgViews,
        SUM(rp.AnswerCount) AS TotalAnswers
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    GROUP BY 
        pt.Name, rp.Score, rp.ViewCount, rp.AnswerCount
)
SELECT 
    ad.PostType,
    ad.PostCount,
    ad.AvgScore,
    ad.AvgViews,
    ad.TotalAnswers,
    CASE 
        WHEN ad.PostCount > 50 THEN 'High Activity'
        WHEN ad.PostCount BETWEEN 20 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    AggregatedData ad
ORDER BY 
    ad.AvgScore DESC, 
    ad.TotalAnswers DESC;
