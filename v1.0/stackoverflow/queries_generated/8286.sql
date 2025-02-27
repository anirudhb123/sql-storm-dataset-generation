WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
PopularUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM RankedPosts
    GROUP BY OwnerUserId
    HAVING COUNT(*) > 5
),
DetailedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pu.PostCount, 0) AS PostCount,
        COALESCE(pu.TotalScore, 0) AS TotalScore,
        COALESCE(pu.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN PopularUsers pu ON u.Id = pu.OwnerUserId
)
SELECT 
    dus.DisplayName,
    dus.PostCount,
    dus.TotalScore,
    dus.TotalViews,
    ph.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM DetailedUserStats dus
LEFT JOIN PostHistory ph ON dus.UserId = ph.UserId
GROUP BY dus.DisplayName, dus.PostCount, dus.TotalScore, dus.TotalViews, ph.Name
ORDER BY dus.TotalScore DESC, dus.PostCount DESC;
