WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COALESCE(au.BadgeCount, 0) AS BadgeCount,
        COALESCE(au.GoldBadges, 0) AS GoldBadges,
        COALESCE(au.SilverBadges, 0) AS SilverBadges,
        COALESCE(au.BronzeBadges, 0) AS BronzeBadges,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    LEFT JOIN 
        UserBadgeStats au ON p.OwnerUserId = au.UserId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
FinalMetrics AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.BadgeCount,
        pd.GoldBadges,
        pd.SilverBadges,
        pd.BronzeBadges,
        pd.Tags,
        RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY pd.BadgeCount DESC) AS BadgeRank
    FROM 
        PostDetails pd
)
SELECT 
    fm.PostId,
    fm.Title,
    fm.CreationDate,
    fm.Score,
    fm.BadgeCount,
    fm.GoldBadges,
    fm.SilverBadges,
    fm.BronzeBadges,
    fm.Tags,
    CASE 
        WHEN fm.ScoreRank = 1 THEN 'Top Scorer'
        ELSE 'Regular Post'
    END AS PostType,
    COALESCE(NULLIF(fm.Tags, ''), 'No Tags') AS DisplayTags
FROM 
    FinalMetrics fm
WHERE 
    fm.Score > (SELECT AVG(Score) FROM Posts) 
    OR (fm.BadgeCount = 0 AND fm.CreationDate <= NOW() - INTERVAL '1 year')
ORDER BY 
    fm.Score DESC, fm.BadgeCount DESC;

In this query:

1. **Common Table Expressions (CTEs)** are used to first retrieve user badge statistics and post details.
2. The `UserBadgeStats` CTE calculates the count of badges per user and categorizes them into Gold, Silver, and Bronze.
3. The `PostDetails` CTE collates post information alongside user badge statistics.
4. The `FinalMetrics` CTE ranks posts based on score and badge count.
5. Various SQL constructs such as `LEFT JOIN`, `COALESCE`, `STRING_AGG`, and window functions (`RANK`, `DENSE_RANK`) are employed for sophisticated data aggregation and transformation.
6. The final `SELECT` statement filters posts based on average score criteria and inclusion of specific tagging logic.

