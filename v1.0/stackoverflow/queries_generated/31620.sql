WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
EnhancedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
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
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(CASE WHEN ph.UserId IS NOT NULL THEN 1 END) AS EditsCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    v.UpVotes,
    v.DownVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ph.CloseReopenCount,
    ph.DeleteUndeleteCount,
    ph.EditsCount
FROM 
    RankedPosts p
LEFT JOIN 
    EnhancedVotes v ON p.PostId = v.PostId
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryCTE ph ON p.PostId = ph.PostId
WHERE 
    p.PostRank = 1 -- Get the latest post per user
ORDER BY 
    p.CreationDate DESC;
