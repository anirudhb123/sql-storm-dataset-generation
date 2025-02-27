WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
TagInfo AS (
    SELECT 
        p.Tags,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        p.Tags
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.LastClosedDate, 'N/A') AS LastClosedDate,
        ti.RelatedPostCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        TagInfo ti ON rp.Tags = ti.Tags
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    CloseCount,
    LastClosedDate,
    RelatedPostCount
FROM 
    FinalResults
WHERE 
    (ViewCount > 100 OR Score > 10) AND 
    (GoldBadges > 0 OR (SilverBadges > 1 AND BronzeBadges > 0))
ORDER BY 
    Score DESC, ViewCount DESC;
