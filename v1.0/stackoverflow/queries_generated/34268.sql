WITH RecursiveTags AS (
    SELECT 
        Id, 
        TagName, 
        Count,
        1 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0
    
    UNION ALL

    SELECT 
        t.Id, 
        t.TagName, 
        t.Count,
        rt.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTags rt ON rt.Id = t.WikiPostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        LastBadgeDate,
        RANK() OVER (ORDER BY BadgeCount DESC) AS UserRank
    FROM 
        UserBadges
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.OwnerUserId
),
FinalStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ps.PostCount,
        ps.TotalViews,
        ps.CommentCount,
        ps.AverageScore,
        ub.BadgeCount, 
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        RANK() OVER (ORDER BY ps.TotalViews DESC) AS ViewRank
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.PostCount,
    fs.TotalViews,
    fs.CommentCount,
    fs.AverageScore,
    fs.BadgeCount,
    fs.GoldBadges,
    fs.SilverBadges,
    fs.BronzeBadges,
    fs.UserRank,
    fs.ViewRank,
    COALESCE(rt.Count, 0) AS TagCount
FROM 
    FinalStatistics fs
LEFT JOIN 
    RecursiveTags rt ON rt.TagName = (SELECT TOP 1 t.TagName FROM Tags t ORDER BY t.Count DESC)
WHERE 
    fs.ViewRank <= 10
ORDER BY 
    fs.TotalViews DESC, fs.UserRank;
