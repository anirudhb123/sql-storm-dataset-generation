
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(ISNULL(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), BadgeStatistics AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), AggregateData AS (
    SELECT 
        us.UserId,
        us.PostCount,
        us.TotalScore,
        us.QuestionCount,
        us.AnswerCount,
        us.AvgViewCount,
        ISNULL(bs.BadgeCount, 0) AS BadgeCount,
        ISNULL(bs.GoldBadgeCount, 0) AS GoldBadgeCount,
        ISNULL(bs.SilverBadgeCount, 0) AS SilverBadgeCount,
        ISNULL(bs.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM 
        UserStatistics us
    LEFT JOIN 
        BadgeStatistics bs ON us.UserId = bs.UserId
)
SELECT 
    a.UserId,
    a.PostCount,
    a.TotalScore,
    a.QuestionCount,
    a.AnswerCount,
    a.AvgViewCount,
    a.BadgeCount,
    a.GoldBadgeCount,
    a.SilverBadgeCount,
    a.BronzeBadgeCount
FROM 
    AggregateData a
WHERE 
    a.TotalScore > 100
ORDER BY 
    a.TotalScore DESC,
    a.PostCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
