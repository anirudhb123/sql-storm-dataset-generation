WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    COALESCE(rp.Score, 0) AS PostScore,
    u.Reputation AS UserReputation,
    u.BadgeCount,
    ch.CloseCount,
    ch.LastCloseDate,
    ch.CloseReasons
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPostHistory ch ON rp.PostId = ch.PostId
WHERE 
    (u.Reputation > 100 OR (u.Reputation BETWEEN 50 AND 100 AND ch.CloseCount > 2))
    AND (rp.PostRank <= 5 OR ch.CloseCount IS NULL)
ORDER BY 
    PostScore DESC, LastCloseDate ASC NULLS LAST;
