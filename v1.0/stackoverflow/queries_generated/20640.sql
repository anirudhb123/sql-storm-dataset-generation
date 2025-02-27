WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year')
),
LatestVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.CreationDate,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= (NOW() - INTERVAL '1 month')
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
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
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(cs.LastCommentDate, NULL) AS LastCommentOn,
    COALESCE(lp.VoteRank, 0) AS LatestVoteRank,
    COALESCE(lp.UserId, NULL) AS LatestVoter,
    bp.GoldBadges,
    bp.SilverBadges,
    bp.BronzeBadges,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentStats cs ON rp.PostId = cs.PostId
LEFT JOIN 
    LatestVotes lp ON rp.PostId = lp.PostId AND lp.VoteRank = 1
LEFT JOIN 
    UserBadges bp ON rp.OwnerUserId = bp.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
