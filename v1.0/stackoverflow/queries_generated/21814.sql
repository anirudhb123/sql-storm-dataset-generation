WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Only questions and answers
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
CloseVotes AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        au.UserId,
        au.Reputation,
        au.GoldBadges,
        au.SilverBadges,
        au.BronzeBadges,
        COALESCE(cv.CloseVoteCount, 0) AS CloseVotes
    FROM 
        RankedPosts rp
    JOIN AggregatedUserStats au ON rp.OwnerUserId = au.UserId
    LEFT JOIN CloseVotes cv ON rp.PostId = cv.PostId
)
SELECT 
    pd.Title AS PostTitle,
    pd.Score AS PostScore,
    pd.ViewCount AS PostViews,
    pd.CreationDate AS PostCreationDate,
    pd.Reputation AS UserReputation,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    CASE 
        WHEN pd.CloseVotes > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.Id = pd.PostId AND p.PostTypeId = pt.Id
    )
WHERE 
    pd.Reputation > 100 -- Only include users with more than 100 reputation
GROUP BY 
    pd.PostId, pd.Title, pd.Score, pd.ViewCount, pd.CreationDate, pd.Reputation, pd.GoldBadges, pd.SilverBadges, pd.BronzeBadges, pd.CloseVotes
HAVING 
    COUNT(pd.UserId) > 0 -- Ensure there's at least one post for the user
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;
