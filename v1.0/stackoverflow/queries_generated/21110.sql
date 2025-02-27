WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- 10 = Closed, 11 = Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    pi.CommentCount,
    pi.UpVotes,
    pi.DownVotes,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostInteractions pi ON rp.PostId = pi.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

-- Additional corner case handling:
-- This section captures posts where the creation date might be NULL or incorrect
UNION ALL
SELECT 
    p.Id,
    COALESCE(p.Title, 'Untitled Post') AS Title,
    0 AS Score,
    0 AS ViewCount,
    COALESCE(p.CreationDate, NOW()) AS CreationDate,
    u.Id AS UserId,
    COALESCE(u.Reputation, 0) AS Reputation,
    0 AS BadgeCount,
    0 AS GoldBadges,
    0 AS SilverBadges,
    0 AS BronzeBadges,
    0 AS CommentCount,
    0 AS UpVotes,
    0 AS DownVotes,
    NULL AS CloseReasons
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate IS NULL
ORDER BY 
    CreationDate DESC
LIMIT 50;
