WITH RecursivePostCTE AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        AcceptedAnswerId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(cl.Name, 'No Reason') AS CloseReason,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        CloseReasonTypes cl ON EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10)
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, cl.Name, u.DisplayName
),
AggregatedStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        Posts
)
SELECT 
    u.DisplayName,
    u.Reputation,
    up.TotalPosts,
    up.TotalBadges,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    ag.TotalPosts AS OverallTotalPosts,
    ag.AvgScore AS OverallAvgScore,
    ag.AvgViewCount AS OverallAvgViewCount
FROM 
    UserReputation up
JOIN 
    PostStats p ON up.UserId = p.OwnerName
CROSS JOIN 
    AggregatedStats ag
WHERE 
    up.Reputation > 1000
ORDER BY 
    p.Score DESC,
    up.TotalPosts DESC;

