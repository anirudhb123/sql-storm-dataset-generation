WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueUsers
    FROM RankedPosts
    GROUP BY PostTypeId
)
SELECT 
    pt.Name AS PostTypeName,
    ad.TotalPosts,
    ad.AvgScore,
    ad.TotalAnswers,
    ad.TotalViews,
    ad.UniqueUsers,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId IN (SELECT PostId FROM RankedPosts)) AS TotalPostHistories
FROM AggregatedData ad
JOIN PostTypes pt ON ad.PostTypeId = pt.Id
WHERE ad.TotalPosts > 0
ORDER BY ad.TotalViews DESC, ad.AvgScore DESC;
