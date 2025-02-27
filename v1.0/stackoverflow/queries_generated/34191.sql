WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
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
),
CloseReasonsAnalytics AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseVotes,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiPosts
    FROM 
        Users u
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
    HAVING 
        COUNT(rp.PostId) > 5
    ORDER BY 
        QuestionsAsked DESC, AnswersPosted DESC
),
MostActiveClosers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ca.CloseVotes,
        ca.LastCloseDate
    FROM 
        CloseReasonsAnalytics ca
    JOIN 
        Users u ON ca.UserId = u.Id
    ORDER BY 
        CloseVotes DESC
    LIMIT 10
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tu.QuestionsAsked,
    tu.AnswersPosted,
    tu.WikiPosts,
    mac.LastCloseDate,
    mac.CloseVotes
FROM 
    TopUsers tu
LEFT JOIN 
    MostActiveClosers mac ON tu.UserId = mac.Id
WHERE 
    (mac.LastCloseDate IS NULL OR mac.LastCloseDate >= DATEADD(YEAR, -1, GETDATE()))
ORDER BY 
    tu.QuestionsAsked DESC, tu.AnswersPosted DESC;
