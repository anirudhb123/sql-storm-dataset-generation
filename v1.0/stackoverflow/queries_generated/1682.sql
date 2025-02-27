WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  -- BountyClose
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReasonName
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id 
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
)
SELECT 
    p.Id,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COALESCE(r.TotalBounty, 0) AS UserTotalBounty,
    c.ClosedDate,
    c.CloseReasonName,
    CASE 
        WHEN p.Score > 100 THEN 'High Score'
        WHEN p.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RecentPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation r ON u.Id = r.UserId
LEFT JOIN 
    ClosedPosts c ON p.Id = c.PostId
WHERE 
    p.rn = 1
ORDER BY 
    p.ViewCount DESC, p.Score DESC;
