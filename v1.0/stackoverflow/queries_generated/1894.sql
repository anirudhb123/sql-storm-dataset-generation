WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason
    FROM 
        PostHistory ph 
    JOIN 
        CloseReasonTypes c ON ph.Comment::INT = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.Id) AS PostCount,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.ViewCount) AS TotalViews,
    MAX(cp.ClosedDate) AS LatestClosedDate,
    STRING_AGG(DISTINCT cp.CloseReason, ', ') AS CloseReasons
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId 
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId 
WHERE 
    u.UserRank <= 10
GROUP BY 
    u.Id
HAVING 
    SUM(rp.ViewCount) > 100
ORDER BY 
    TotalViews DESC;
