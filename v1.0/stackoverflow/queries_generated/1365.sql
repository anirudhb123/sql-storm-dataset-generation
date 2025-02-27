WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS history_rank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete actions
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Upvotes,
    us.Downvotes,
    us.TotalPosts,
    rp.Title AS LatestPostTitle,
    rp.Score AS LatestPostScore,
    rp.ViewCount AS LatestPostViews,
    COALESCE(phd.UserDisplayName, 'No History') AS LastActionBy,
    COALESCE(phd.CreationDate, 'N/A') AS LastActionDate,
    COALESCE(phd.Comment, 'N/A') AS LastActionComment
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId AND phd.history_rank = 1
WHERE 
    us.Reputation > 1000 
ORDER BY 
    us.Reputation DESC, us.DisplayName ASC
LIMIT 100;
