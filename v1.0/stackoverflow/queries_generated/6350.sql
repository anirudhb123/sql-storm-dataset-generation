WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM Posts p
        LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
        LEFT JOIN STRING_SPLIT(p.Tags, '>') AS tagSplit ON tagSplit.value IS NOT NULL
        LEFT JOIN Tags t ON t.TagName = TRIM(tagSplit.value)
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS TotalPosts,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS OverallRank
    FROM Users u
        JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ru.UserRank,
    tu.OverallRank,
    tu.DisplayName,
    ru.PostId,
    ru.Title,
    ru.CreationDate,
    ru.ViewCount,
    ru.Score,
    ru.AnswerCount,
    ru.Tags,
    tu.TotalViews,
    tu.TotalScore,
    tu.TotalPosts
FROM RankedPosts ru
JOIN TopUsers tu ON ru.OwnerUserId = tu.UserId
ORDER BY ru.UserRank, tu.OverallRank;
