
WITH UserTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.TagName) AS UniqueTagsContributed,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT DISTINCT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName, 
            p.Id AS PostId
        FROM 
            Posts p 
        JOIN 
            (SELECT 
                1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
        WHERE 
            p.PostTypeId = 1) t ON p.Id = t.PostId
    GROUP BY 
        u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), CombinedStats AS (
    SELECT 
        ut.UserId,
        ut.DisplayName,
        ut.UniqueTagsContributed,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ut.AcceptedAnswers,
        ut.TotalViews,
        ut.TotalScore
    FROM 
        UserTags ut
    LEFT JOIN 
        UserBadges ub ON ut.UserId = ub.UserId
)

SELECT 
    *,
    COALESCE(TotalViews / NULLIF(AcceptedAnswers, 0), 0) AS ViewsPerAcceptedAnswer,
    COALESCE(TotalScore / NULLIF(UniqueTagsContributed, 0), 0) AS ScorePerTag
FROM 
    CombinedStats
ORDER BY 
    TotalScore DESC, UniqueTagsContributed DESC
LIMIT 10;
