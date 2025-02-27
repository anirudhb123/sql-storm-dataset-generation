WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(up.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(down.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) up ON p.Id = up.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) down ON p.Id = down.PostId
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS ClosedCount 
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pc.CommentCount,
    COALESCE(cp.ClosedCount, 0) AS ClosedCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;

WITH UserBadges AS (
    SELECT 
        b.UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    COALESCE(ub.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(ub.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadgeCount, 0) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.LastAccessDate > CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    u.Reputation DESC
LIMIT 10;
