WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Considering only questions and answers
),
AggregatedData AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AverageViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  -- Top 10 posts by type
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    ad.OwnerDisplayName,
    ad.TotalPosts,
    ad.TotalScore,
    ad.AverageViewCount,
    ROW_NUMBER() OVER (ORDER BY ad.TotalScore DESC) AS PerformanceRank
FROM 
    AggregatedData ad
ORDER BY 
    ad.PerformanceRank;
