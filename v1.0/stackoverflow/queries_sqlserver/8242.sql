
WITH RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(c.Id, 0)) AS CommentCount,
        SUM(ISNULL(v.Id, 0)) AS VoteCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate > CAST('2024-10-01' AS DATE) - DATEADD(year, 1, 0)
    GROUP BY 
        u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), CombinedData AS (
    SELECT 
        rua.UserId,
        rua.DisplayName,
        rua.PostCount,
        rua.TotalViews,
        rua.CommentCount,
        rua.VoteCount,
        rua.AcceptedAnswers,
        rua.LastPostDate,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        RecentUserActivity rua
    LEFT JOIN 
        UserBadges ub ON rua.UserId = ub.UserId
)
SELECT 
    * 
FROM 
    CombinedData
ORDER BY 
    TotalViews DESC, 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
