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
        p.Score > 0 AND 
        p.CreationDate >= NOW() - INTERVAL '30 days'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    us.DisplayName AS Owner,
    us.PostCount,
    us.CommentCount,
    ct.CloseCount,
    ct.LastClosedDate,
    CASE 
        WHEN ct.CloseCount > 0 
        THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RankedPosts p
JOIN 
    UserStats us ON p.PostId = us.UserId
LEFT JOIN 
    ClosedPosts ct ON p.PostId = ct.PostId
WHERE 
    EXISTS (
        SELECT 1 
        FROM Tags t 
        WHERE t.ExcerptPostId = p.PostId 
          AND t.IsModeratorOnly = 0
    ) 
    AND NOT EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = p.PostId 
          AND c.Score < 0
    )
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
