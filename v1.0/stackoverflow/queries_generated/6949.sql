WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
), 
BadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS TotalBadges,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY b.UserId
), 
PostHistoryStats AS (
    SELECT 
        ph.UserId, 
        COUNT(ph.Id) AS TotalEdits, 
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TotalClosedPosts
    FROM 
        PostHistory ph
    GROUP BY ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpVotes,
    us.TotalDownVotes,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(phs.TotalEdits, 0) AS TotalEdits,
    COALESCE(phs.TotalClosedPosts, 0) AS TotalClosedPosts
FROM 
    UserStats us
LEFT JOIN 
    BadgeCounts bc ON us.UserId = bc.UserId
LEFT JOIN 
    PostHistoryStats phs ON us.UserId = phs.UserId
ORDER BY 
    us.Reputation DESC
LIMIT 50;
