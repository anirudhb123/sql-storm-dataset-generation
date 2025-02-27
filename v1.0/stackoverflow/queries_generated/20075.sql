WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen types
        AND ph.CreationDate >= NOW() - INTERVAL '30 days'
),
CountUserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserPostRank,
        COALESCE(rc.CloseReason, 'No closure') AS ClosureStatus,
        cb.BadgeCount,
        cb.GoldBadges,
        cb.SilverBadges,
        cb.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentPostHistory rc ON rp.PostId = rc.PostId
    LEFT JOIN 
        CountUserBadges cb ON rp.OwnerUserId = cb.UserId
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.UserPostRank,
    f.ClosureStatus,
    COALESCE((f.UpVotesCount - f.DownVotesCount), 0) AS NetVotes,
    CASE 
        WHEN f.BadgeCount IS NULL THEN 'No Badges'
        ELSE CONCAT('Badges - Total: ', f.BadgeCount, 
                    ', Gold: ', f.GoldBadges, 
                    ', Silver: ', f.SilverBadges, 
                    ', Bronze: ', f.BronzeBadges) 
    END AS BadgeDetails
FROM 
    FinalReport f
WHERE 
    f.UserPostRank = 1 -- Only latest post for each user
ORDER BY 
    f.Score DESC, f.ViewCount DESC
LIMIT 50;

This query combines various SQL constructs to provide an insightful report on questions posted by users along with their closure status, net votes, and badge information within the specified time frame, focusing on recent activity and user engagement metrics. The use of CTEs enables modular code organization, while window functions facilitate ranking posts and aggregating votes. The query also demonstrates intricacies like the treatment of NULL values and dynamic string concatenation for badge details.
