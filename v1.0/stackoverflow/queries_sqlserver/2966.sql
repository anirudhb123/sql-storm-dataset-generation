
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        AVG(ISNULL(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(pa.Id) AS AcceptedCount
    FROM 
        Posts p
    JOIN 
        Posts pa ON p.AcceptedAnswerId = pa.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Id) AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.AvgViewCount,
        COALESCE(aa.AcceptedCount, 0) AS AcceptedAnswers,
        COALESCE(ub.BadgeCount, 0) AS GoldBadges,
        COALESCE(ub.BadgeNames, 'None') AS GoldBadgeNames
    FROM 
        UserPostStats ups
    LEFT JOIN 
        AcceptedAnswers aa ON ups.UserId = aa.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON ups.UserId = ub.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount,
    TotalScore,
    AvgViewCount,
    AcceptedAnswers,
    GoldBadges,
    GoldBadgeNames
FROM 
    FinalStats
WHERE 
    TotalScore > 1000
ORDER BY 
    TotalScore DESC,
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
