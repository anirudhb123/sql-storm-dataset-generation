WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2)  -- Only questions and answers
), 

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation IS NOT NULL -- Exclude users with NULL reputation
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 

PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM RankedPosts rp
    JOIN UserStats us ON rp.PostId = us.UserId 
    WHERE rp.PostRank = 1 -- Most recent post for each user
), 

CloseVoteCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Votes to close
    GROUP BY ph.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount AS CurrentViewCount,
    COALESCE(cvc.CloseVoteCount, 0) AS TotalCloseVotes,
    pd.Score,
    pd.DisplayName AS Owner,
    pd.Reputation,
    pd.PostCount,
    pd.GoldBadges + pd.SilverBadges + pd.BronzeBadges AS TotalBadges
FROM PostDetails pd
LEFT JOIN CloseVoteCounts cvc ON pd.PostId = cvc.PostId
WHERE pd.Reputation > 500 -- Only include users with significant reputation
  AND (pd.ViewCount > 50 OR (pd.Score >= 10 AND pd.ViewCount IS NOT NULL))
ORDER BY COALESCE(cvc.CloseVoteCount, 0) DESC, pd.Score DESC
LIMIT 10; -- Top 10 posts after filtering

