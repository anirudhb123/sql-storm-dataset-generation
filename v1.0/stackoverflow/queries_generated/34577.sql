WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Select only Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        p.Title,
        a.CreationDate,
        a.AcceptedAnswerId,
        a.ViewCount,
        a.Score,
        a.OwnerUserId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE p ON a.ParentId = p.PostId
    WHERE 
        a.PostTypeId = 2 -- Select only Answers
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostsParticipatedCount,
        SUM(CASE WHEN pm.Level = 1 THEN 1 ELSE 0 END) AS TopLevelQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        RecursivePostCTE pm ON p.Id = pm.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.Reputation,
    ue.QuestionCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    ue.TotalBounty,
    ue.TotalViews,
    ue.PostsParticipatedCount,
    ue.TopLevelQuestions
FROM 
    UserEngagement ue
LEFT JOIN 
    UserBadges ub ON ue.UserId = ub.UserId
WHERE 
    ue.Reputation > 1000 -- Filter for users with high reputation
ORDER BY 
    ue.TotalViews DESC, ue.Reputation DESC;

