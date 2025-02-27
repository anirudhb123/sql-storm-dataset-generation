
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT ct.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    INNER JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    INNER JOIN 
        CloseReasonTypes ct ON ph.Comment = CAST(ct.Id AS VARCHAR(255))
    WHERE 
        ht.Name = 'Post Closed'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    COALESCE(up.Reputation, 0) AS UserReputation,
    COALESCE(up.TotalBadgeClass, 0) AS TotalBadgeClass,
    MAX(CASE WHEN ph.rn = 1 THEN ph.CreationDate END) AS MostRecentActivity,
    COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation up ON u.Id = up.UserId
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    p.CreationDate > DATEADD(YEAR, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
AND 
    p.ViewCount IS NOT NULL 
AND 
    (p.Score IS NULL OR p.Score > 5)
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, up.Reputation, up.TotalBadgeClass, cp.CloseReasonCount, cp.CloseReasons
ORDER BY 
    p.Score DESC, UserReputation DESC, MostRecentActivity DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
