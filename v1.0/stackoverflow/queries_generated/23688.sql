WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(co.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            ELSE 'Elite'
        END AS ReputationTier
    FROM 
        Users u
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.ReputationTier
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.ReputationTier,
        COALESCE(cp.FirstClosedDate, 'No closure') AS FirstClosedDate,
        COALESCE(cp.LastClosedDate, 'No closure') AS LastClosedDate,
        COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        ClosedPosts cp ON tp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.ReputationTier,
    ps.FirstClosedDate,
    ps.LastClosedDate,
    ps.CloseReasonCount,
    CASE 
        WHEN ps.CloseReasonCount > 0 THEN 'This post has been closed'
        ELSE 'This post is open'
    END AS PostStatus,
    CASE 
        WHEN ps.Score >= 10 THEN 'Highly Rated'
        WHEN ps.Score BETWEEN 0 AND 9 THEN 'Moderately Rated'
        ELSE 'Low Rating'
    END AS RatingDescription
FROM 
    PostStatistics ps
WHERE 
    ps.ViewCount > 50
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 100;
