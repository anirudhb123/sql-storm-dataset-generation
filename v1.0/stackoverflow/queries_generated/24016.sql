WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(DISTINCT v.PostId) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        v.UserId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

FinalPostResults AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(uvc.VoteCount, 0) AS UserVoteCount,
        COALESCE(pbd.BadgeCount, 0) AS UserBadgeCount,
        phd.HistoryTypes,
        phd.LastEditDate
    FROM 
        RankedPosts p
    LEFT JOIN 
        UserVoteCounts uvc ON uvc.UserId = p.OwnerUserId
    LEFT JOIN 
        UserBadges pbd ON pbd.UserId = p.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails phd ON phd.PostId = p.PostId
    WHERE 
        p.Rank <= 5
)

SELECT 
    fpr.Title,
    fpr.Score,
    fpr.UserVoteCount,
    fpr.UserBadgeCount,
    fpr.HistoryTypes,
    fpr.LastEditDate
FROM 
    FinalPostResults fpr
WHERE 
    fpr.UserVoteCount > 0
ORDER BY 
    fpr.Score DESC, fpr.UserVoteCount DESC;

