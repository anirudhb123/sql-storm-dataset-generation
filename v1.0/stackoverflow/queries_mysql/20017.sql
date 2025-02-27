
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 ELSE 0 END), 0) AS SuggestedEdits,
        COUNT(CASE WHEN p.LastActivityDate >= NOW() - INTERVAL 30 DAY THEN 1 END) AS RecentActivityCount 
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
),
CombinedUserData AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ra.CloseVotes, 0) AS CloseVotes,
        COALESCE(ra.SuggestedEdits, 0) AS SuggestedEdits,
        COALESCE(ra.RecentActivityCount, 0) AS RecentActivityCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        RecentPostActivity ra ON u.Id = ra.OwnerUserId
)
SELECT 
    u.Id,
    u.DisplayName,
    COALESCE(NULLIF(u.Reputation, 0), 1) AS AdjustedReputation,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    (u.CloseVotes + u.SuggestedEdits) AS TotalEngagement,
    CASE 
        WHEN u.Reputation IS NULL OR u.Reputation < 50 THEN 'Newbie' 
        WHEN u.Reputation BETWEEN 50 AND 200 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel,
    CASE 
        WHEN u.RecentActivityCount > 5 THEN 'Active'
        WHEN u.RecentActivityCount BETWEEN 1 AND 5 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS ActivityStatus,
    @rank := IF(@prev_level = 
        CASE 
            WHEN u.Reputation IS NULL OR u.Reputation < 50 THEN 'Newbie' 
            WHEN u.Reputation BETWEEN 50 AND 200 THEN 'Intermediate'
            ELSE 'Expert'
        END, @rank + 1, 1) AS RankWithinLevel,
    @prev_level := CASE 
        WHEN u.Reputation IS NULL OR u.Reputation < 50 THEN 'Newbie' 
        WHEN u.Reputation BETWEEN 50 AND 200 THEN 'Intermediate'
        ELSE 'Expert'
    END
FROM 
    CombinedUserData u,
    (SELECT @rank := 0, @prev_level := '') AS vars
WHERE 
    u.CreationDate < NOW() - INTERVAL 2 YEAR
ORDER BY 
    UserLevel, AdjustedReputation DESC;
