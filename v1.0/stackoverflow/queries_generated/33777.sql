WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only questions
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(rb.BadgeCount, 0) AS BadgeCount,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Users u
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.UserPostRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, rp.Title, rp.ViewCount, rp.CreationDate, cp.CloseVoteCount
ORDER BY 
    u.Reputation DESC, rp.ViewCount DESC NULLS LAST
LIMIT 100
OFFSET 0;
