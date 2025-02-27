WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
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
PostHistorySummary AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT
    p.Id,
    p.Title,
    p.CreationDate,
    up.DisplayName AS OwnerDisplayName,
    COALESCE(up.Reputation, 0) AS OwnerReputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.HistoryTypes,
    phs.EditorCount,
    phs.LastEditDate,
    (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    COALESCE(rp.Rank, NULL) AS UserPostRank
FROM 
    Posts p
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
WHERE 
    phs.EditorCount > 5 -- Only consider posts edited by more than 5 users
    AND (p.ClosedDate IS NULL OR p.ClosedDate < NOW() - INTERVAL '30 days') -- Exclude closed posts older than 30 days
ORDER BY 
    p.Score DESC, OwnerReputation DESC
LIMIT 100;

-- Additional complexity with a window function and correlated subquery to derive insights
WITH FinalPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBountyAwarded,
        LAST_VALUE(v.CreationDate) OVER (PARTITION BY p.Id ORDER BY v.CreationDate RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastVoteDate,
        COALESCE(CAST(NULLIF(p.AcceptedAnswerId, -1) IS NOT NULL AS INT), 0) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
)
SELECT 
    Title,
    ViewCount,
    TotalBountyAwarded,
    LastVoteDate,
    HasAcceptedAnswer
FROM 
    FinalPosts
WHERE 
    HasAcceptedAnswer = 1
    AND LastVoteDate >= NOW() - INTERVAL '6 months'
ORDER BY 
    TotalBountyAwarded DESC;
