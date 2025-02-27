WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,  -- Count Upvotes
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount  -- Count Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseHistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Close and Reopen history
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '2 years'  -- Badges earned in the last two years
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.CreationDate,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    COALESCE(cb.Comment, 'No close history') AS CloseHistoryComment,
    COALESCE(cb.CreationDate, 'N/A') AS CloseHistoryDate,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    ClosedPostHistories cb ON rp.PostId = cb.PostId AND cb.CloseHistoryRank = 1  -- Most recent close
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.PostRank = 1  -- Most recent post per user
    AND (ub.BadgeCount IS NULL OR ub.BadgeCount > 0)  -- Consider only users with badges, or none
ORDER BY 
    rp.CommentCount DESC, rp.UpvoteCount DESC
LIMIT 100;  -- Limit to top 100 users
