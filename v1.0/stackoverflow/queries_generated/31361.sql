WITH RECURSIVE UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount END) AS TotalAcceptedAnswers
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    COALESCE(uba.GoldBadges, 0) AS GoldBadges,
    COALESCE(uba.SilverBadges, 0) AS SilverBadges,
    COALESCE(uba.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(phag.EditCount, 0) AS EditCount,
    phag.LastEditDate,
    phag.HistoryTypes
FROM 
    UserPostStats ups
LEFT JOIN UserBadges uba ON ups.UserId = uba.UserId
LEFT JOIN PostHistoryAggregated phag ON ups.UserId IN (
    SELECT 
        p.OwnerUserId 
    FROM 
        Posts p 
    WHERE 
        p.Id = phag.PostId
)
WHERE 
    ups.TotalPosts > 5
ORDER BY 
    ups.TotalQuestions DESC, ups.DisplayName;
