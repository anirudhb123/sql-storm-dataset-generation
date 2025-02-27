WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId IN (2, 4)) AS Upvotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.ViewCount IS NOT NULL 
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bs.GoldBadges, 0) + COALESCE(bs.SilverBadges, 0) + COALESCE(bs.BronzeBadges, 0) AS TotalBadges,
        COUNT(ps.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        UserBadges bs ON u.Id = bs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, bs.GoldBadges, bs.SilverBadges, bs.BronzeBadges
),
RankedPosts AS (
    SELECT 
        ps.*,
        COALESCE(NULLIF(u.TotalBadges, 0), 1) AS BadgeDiversity
    FROM 
        PostStats ps
    LEFT JOIN 
        TopUsers u ON ps.OwnerUserId = u.UserId
    WHERE 
        ps.CommentCount > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    rp.RecentPostRank,
    u.DisplayName,
    u.TotalBadges,
    rp.BadgeDiversity,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question' 
        WHEN rp.PostTypeId = 2 THEN 'Answer' 
        ELSE 'Other' END AS PostType
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
ORDER BY 
    rp.Upvotes DESC, 
    rp.CreationDate ASC;
