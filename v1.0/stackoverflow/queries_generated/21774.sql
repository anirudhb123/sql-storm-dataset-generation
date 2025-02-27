WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= current_date - INTERVAL '1 year'
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopened
    FROM PostHistory ph
    LEFT JOIN Posts p ON ph.PostId = p.Id
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN ph.LastClosed IS NOT NULL AND (ph.LastReopened IS NULL OR ph.LastClosed > ph.LastReopened) THEN 'Closed'
            WHEN ph.LastClosed IS NULL AND ph.LastReopened IS NOT NULL THEN 'Previously Closed'
            ELSE 'Open'
        END AS PostStatus,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM RankedPosts rp
    JOIN Users u ON rp.UserPostRank = 1 AND rp.OwnerUserId = u.Id
    LEFT JOIN PostHistoryDetails ph ON rp.PostId = ph.PostId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.Score > 0
        AND (ub.GoldBadges > 0 OR ub.SilverBadges > 0 OR ub.BronzeBadges > 0)
    ORDER BY rp.Score DESC, rp.CommentCount ASC
)
SELECT 
    *,
    CASE 
        WHEN GoldBadges > 0 THEN 'Gold Contributor'
        WHEN SilverBadges > 0 THEN 'Silver Contributor'
        WHEN BronzeBadges > 0 THEN 'Bronze Contributor'
        ELSE 'No Badge'
    END AS ContributorLevel
FROM FinalReport
WHERE PostStatus = 'Open' OR PostStatus = 'Previously Closed'
ORDER BY PostStatus, Score DESC;
