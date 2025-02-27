WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes, -- Downvotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(cp.CloseDate, 'N/A') AS LastClosedDate,
    COALESCE(cp.UserDisplayName, 'N/A') AS ClosedBy,
    COALESCE(cp.Comment, 'N/A') AS CloseComment,
    COALESCE(ub.BadgeCount, 0) AS RecentBadgeCount
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.UserPostRank <= 5 -- Top 5 posts by user
ORDER BY 
    u.Reputation DESC, 
    rp.ViewCount DESC;
