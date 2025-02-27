WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
BadgeCounts AS (
    SELECT
        b.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),
UserStatistics AS (
    SELECT
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalPosts,
        ur.TotalAnswers,
        ur.AcceptedAnswers,
        COALESCE(bc.TotalBadges, 0) AS TotalBadges,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM
        UserReputation ur
    LEFT JOIN
        BadgeCounts bc ON ur.UserId = bc.UserId
),
MostActiveUsers AS (
    SELECT
        UserId,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS rn
    FROM
        UserStatistics
    WHERE
        TotalPosts > 0
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        p.PostTypeId,
        CASE
            WHEN p.ParentId IS NOT NULL THEN 'Answer'
            WHEN p.PostTypeId = 1 THEN 'Question'
            ELSE 'Other'
        END AS PostKind
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
FinalResults AS (
    SELECT
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalAnswers,
        us.AcceptedAnswers,
        us.TotalBadges,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COUNT(rp.PostId) AS RecentPostCount,
        SUM(CASE WHEN rp.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN rp.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted
    FROM
        UserStatistics us
    LEFT JOIN
        RecentPosts rp ON us.UserId = rp.OwnerId
    WHERE
        us.Reputation IS NOT NULL
    GROUP BY
        us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalAnswers,
        us.AcceptedAnswers, us.TotalBadges, us.GoldBadges, us.SilverBadges,
        us.BronzeBadges
    HAVING
        us.TotalPosts > 2 AND us.Reputation > 1000
)
SELECT
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.TotalPosts,
    fr.TotalAnswers,
    fr.AcceptedAnswers,
    fr.TotalBadges,
    fr.GoldBadges,
    fr.SilverBadges,
    fr.BronzeBadges,
    fr.RecentPostCount,
    fr.QuestionsPosted,
    fr.AnswersPosted,
    CASE
        WHEN fr.RecentPostCount > 5 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    CASE
        WHEN fr.BronzeBadges > 10 THEN 'Bronze Enthusiast'
        WHEN fr.GoldBadges > 5 THEN 'Gold Leader'
        ELSE 'Regular User'
    END AS BadgeLevel,
    (SELECT COUNT(*) FROM Comment c WHERE c.UserId = fr.UserId) AS TotalComments,
    DENSE_RANK() OVER (ORDER BY fr.Reputation DESC) AS ReputationRank
FROM
    Final
