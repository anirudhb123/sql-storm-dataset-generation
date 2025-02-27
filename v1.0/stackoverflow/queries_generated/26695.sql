WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Focus on Questions only
),
RecentUserQuestions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(rp.PostId) > 0
),
BadgesSummary AS (
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
),
CombinedResults AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        q.QuestionCount,
        q.TotalScore,
        q.TotalViews,
        b.BadgeCount,
        b.GoldBadges,
        b.SilverBadges,
        b.BronzeBadges
    FROM 
        RecentUserQuestions u
    JOIN 
        BadgesSummary b ON u.UserId = b.UserId
)

SELECT 
    cr.DisplayName,
    cr.QuestionCount,
    cr.TotalScore,
    cr.TotalViews,
    cr.BadgeCount,
    cr.GoldBadges,
    cr.SilverBadges,
    cr.BronzeBadges
FROM 
    CombinedResults cr
ORDER BY 
    cr.QuestionCount DESC, cr.TotalScore DESC
LIMIT 10;

This SQL query benchmarks string processing by analyzing user-generated questions on a Stack Overflow-like schema. It focuses on users who created accounts within the last year, counts their question activity, and evaluates their badge accumulation, ultimately providing a leaderboard of the top contributors based on question engagement and reputation metrics.
