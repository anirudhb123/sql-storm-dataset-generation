WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.OwnerUserId, 
        rp.Title, 
        rp.ViewCount, 
        rp.CreationDate, 
        rp.UpVoteCount, 
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.PostsCount,
    tp.Title,
    tp.ViewCount,
    tp.UpVoteCount,
    tp.DownVoteCount
FROM 
    UserStats us
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId
ORDER BY 
    us.Reputation DESC, tp.ViewCount DESC NULLS LAST;
