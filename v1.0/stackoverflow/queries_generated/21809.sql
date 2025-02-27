WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId, p.CreationDate
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        AVG(b.Class * 1.0) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 52 THEN ph.CreationDate END) AS HotQuestionDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN ph.Id END) AS ClosureCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    u.DisplayName AS Owner,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    ph.ClosedDate,
    ph.HotQuestionDate,
    COALESCE(reviews.rn, 0) AS Ranking,
    ue.PostsCreated,
    ue.TotalBounties,
    ue.BadgesCount,
    ue.AvgBadgeClass
FROM 
    Posts p 
LEFT JOIN 
    RankedPosts reviews ON p.Id = reviews.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 
    AND (p.ViewCount IS NOT NULL OR p.Score IS NOT NULL) 
    AND (p.ClosedDate IS NULL OR ph.ClosureCount < 2)
ORDER BY 
    COALESCE(reviews.ViewCount, 0) DESC, 
    COALESCE(ue.TotalBounties, 0) DESC,
    p.CreationDate DESC
LIMIT 100;

