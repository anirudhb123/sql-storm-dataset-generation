WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(upvote_count, 0) AS UpVotes,
        COALESCE(downvote_count, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS upvote_count,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS downvote_count
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
), 
ClosedPosts AS (
    SELECT 
        h.PostId,
        MIN(h.CreationDate) AS FirstCloseDate,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory h
    JOIN 
        CloseReasonTypes c ON h.Comment::INT = c.Id
    WHERE 
        h.PostHistoryTypeId = 10 
    GROUP BY 
        h.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY COUNT(b.Id) DESC) AS BadgeRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.UpVotes,
    p.DownVotes,
    p.Score,
    cl.FirstCloseDate,
    cl.CloseReasons,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    Users up
JOIN 
    RankedPosts p ON up.Id = p.OwnerUserId
LEFT JOIN 
    ClosedPosts cl ON p.PostId = cl.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    (p.UpVotes - p.DownVotes) > 5 
    AND (cl.FirstCloseDate IS NULL OR cl.FirstCloseDate > current_date - INTERVAL '30 days')
    AND up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, 
    p.Score DESC,
    p.CreationDate ASC
LIMIT 100;
