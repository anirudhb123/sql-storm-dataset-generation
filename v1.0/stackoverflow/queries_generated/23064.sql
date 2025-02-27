WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1  -- Questions only
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,  -- Upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount  -- Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,  -- Gold badges
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,  -- Silver badges
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount   -- Bronze badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.Score,
    av.UpVoteCount,
    av.DownVoteCount,
    ubc.GoldBadgeCount,
    ubc.SilverBadgeCount,
    ubc.BronzeBadgeCount,
    COALESCE(ubc.GoldBadgeCount + ubc.SilverBadgeCount * 0.5 + ubc.BronzeBadgeCount * 0.25, 0) AS BadgeScore,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Newest Post by User'
        ELSE 'Older Posts by User'
    END AS PostStatus,
    CASE 
        WHEN COALESCE(av.UpVoteCount - av.DownVoteCount, 0) > 0 THEN 'Positive Engagement'
        WHEN COALESCE(av.UpVoteCount - av.DownVoteCount, 0) < 0 THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
WHERE 
    COALESCE(av.UpVoteCount, 0) > 5 -- Only show posts with more than 5 upvotes
    OR ubc.GoldBadgeCount > 0 -- Users with at least one gold badge
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
