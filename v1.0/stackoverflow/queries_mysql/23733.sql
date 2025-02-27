
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate, u.DisplayName
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
), AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(a.Id) AS AcceptedAnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
), PostHistoryCount AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.UserId
), UserSummary AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        COALESCE(rp.PostRank, 0) AS RecentPostRank,
        COALESCE(a.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COALESCE(ph.EditCount, 0) AS TotalEdits
    FROM 
        UserMetrics um
    LEFT JOIN 
        RecentPosts rp ON um.UserId = rp.OwnerUserId AND rp.PostRank = 1
    LEFT JOIN 
        AcceptedAnswers a ON um.UserId = a.OwnerUserId
    LEFT JOIN 
        PostHistoryCount ph ON um.UserId = ph.UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    CASE 
        WHEN us.Reputation >= 10000 THEN 'High Reputation'
        WHEN us.Reputation BETWEEN 5000 AND 9999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    us.RecentPostRank AS MostRecentPostRank,
    us.AcceptedAnswerCount,
    us.TotalEdits,
    CASE 
        WHEN us.Reputation IS NULL THEN 'No Reputation Data'
        ELSE NULL
    END AS ReputationNullCheck
FROM 
    UserSummary us
WHERE 
    us.Reputation >= 10000
ORDER BY 
    us.Reputation DESC 
LIMIT 10;
