WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankWithinUser,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title AS ClosedPostTitle,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS WasClosed
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate, p.Title
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostRankSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(pb.GoldCount, 0) AS GoldBadges,
        COALESCE(pb.SilverCount, 0) AS SilverBadges,
        COALESCE(pb.BronzeCount, 0) AS BronzeBadges,
        closed.WasClosed,
        CASE 
            WHEN rp.RankWithinUser = 1 THEN 'Top Post'
            WHEN rp.RankWithinUser <= 3 THEN 'Top 3 Posts'
            ELSE 'Other'
        END AS PostRanking
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadgeCounts pb ON rp.OwnerUserId = pb.UserId
    LEFT JOIN 
        ClosedPostHistory closed ON rp.PostId = closed.PostId
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    CASE 
        WHEN WasClosed = 1 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    PostRanking
FROM 
    PostRankSummary
WHERE 
    (GoldBadges > 0 OR SilverBadges > 1)
    AND (Score > 10 OR ClosedPostTitle IS NOT NULL)
ORDER BY 
    Score DESC, ViewCount DESC, GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC;
