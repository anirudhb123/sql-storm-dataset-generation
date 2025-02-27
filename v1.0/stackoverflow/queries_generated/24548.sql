WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider posts from the last year
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        PH.UserId AS CloserId,
        PH.CreationDate AS ClosedDate,
        PH.Comment AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        Posts p ON PH.PostId = p.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- 10 indicates that the post was closed
),
RelatedPosts AS (
    SELECT 
        pl.PostId AS PrimaryPostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        lt.Name IN ('Linked', 'Duplicate') -- We only care about linked or duplicated posts
),
FinalResults AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.ViewCount,
        rb.GoldBadges,
        rb.SilverBadges,
        rb.BronzeBadges,
        COALESCE(cp.CloserId, -1) AS CloserId,
        COALESCE(cp.ClosedDate, '1970-01-01') AS ClosedDate,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
        COUNT(DISTINCT r.RelatedPostId) AS RelatedPostCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.Id
    LEFT JOIN 
        RelatedPosts r ON rp.Id = r.PrimaryPostId
    WHERE 
        rp.Rank <= 10 -- Selecting top 10 posts per type
    GROUP BY 
        rp.Id, rb.GoldBadges, rb.SilverBadges, rb.BronzeBadges, cp.CloserId, cp.ClosedDate, cp.CloseReason
)
SELECT 
    *,
    (CASE 
        WHEN ClosedDate <> '1970-01-01' THEN 'Closed' 
        ELSE 'Open' 
     END) AS PostStatus,
    (GoldBadges + SilverBadges + BronzeBadges) AS TotalBadges
FROM 
    FinalResults
ORDER BY 
    ViewCount DESC;

