WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- UpMod votes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserId,
        u.DisplayName AS ModeratorDisplayName
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
),
TagAggregate AS (
    SELECT 
        p.Id AS PostId,
        string_agg(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ',') AS tags ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = trim(both ' ' from unnest(tags))
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.VoteCount,
    ta.Tags,
    cp.CloseReason,
    cp.ModeratorDisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    TagAggregate ta ON rp.PostId = ta.PostId
LEFT JOIN 
    UserBadges ub ON rp.PostId = ub.UserId
WHERE 
    (rp.Rank <= 5 OR cp.PostId IS NOT NULL)  -- Return top 5 ranked posts or any closed posts
ORDER BY 
    rp.Score DESC NULLS LAST,
    rp.ViewCount DESC;

