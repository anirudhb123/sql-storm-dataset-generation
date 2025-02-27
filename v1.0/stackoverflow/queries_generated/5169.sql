WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upmod
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.PostTypeId IN (1, 2) -- Considering Questions and Answers only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserParticipation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation >= 1000 -- Consider users with reasonable reputation
    GROUP BY 
        u.Id, u.DisplayName
),
PostHighlights AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        up.UserDisplayName,
        up.PostsCount,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserParticipation up ON rp.OwnerUserId = up.UserId
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.Score,
    ph.ViewCount,
    ph.CommentCount,
    ph.VoteCount,
    ph.UserDisplayName,
    ph.PostsCount,
    ph.GoldBadges,
    ph.SilverBadges,
    ph.BronzeBadges
FROM 
    PostHighlights ph
ORDER BY 
    ph.Score DESC, ph.ViewCount DESC;
