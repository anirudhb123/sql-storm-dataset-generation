WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
), 
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Votes v
    WHERE v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    GROUP BY v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
)
SELECT 
    up.Id AS PostId,
    up.Title,
    up.CreationDate AS QuestionDate,
    up.Score,
    up.ViewCount,
    uv.TotalBadges,
    uv.GoldBadges,
    uv.SilverBadges,
    uv.BronzeBadges,
    COALESCE(rv.VoteCount, 0) AS VoteCount,
    COALESCE(rv.LastVoteDate, 'No votes') AS LastVoteDate,
    COUNT(DISTINCT pht.PostHistoryTypeId) AS ModificationCount
FROM RankedPosts up
LEFT JOIN Users u ON up.OwnerUserId = u.Id
LEFT JOIN UserBadges uv ON u.Id = uv.UserId
LEFT JOIN RecentVotes rv ON up.Id = rv.PostId
LEFT JOIN PostHistoryChanges pht ON up.Id = pht.PostId
WHERE up.rn = 1  -- Get only the most recent post per user
GROUP BY up.Id, up.Title, up.CreationDate, up.Score, up.ViewCount, uv.TotalBadges, 
         uv.GoldBadges, uv.SilverBadges, uv.BronzeBadges, rv.VoteCount, rv.LastVoteDate
ORDER BY up.CreationDate DESC
LIMIT 50;
