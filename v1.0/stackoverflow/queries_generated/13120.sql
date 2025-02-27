-- Performance benchmarking query to analyze the interaction between Posts and their associated data
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP) -- Only consider posts from the last year
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges, 
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId = us.PostId -- Assuming the user contributed to the post
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
