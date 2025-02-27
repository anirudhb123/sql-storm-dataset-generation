WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.Score > 10
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), 
RecentPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate, 
        ph.UserId,
        p.Title,
        p.OwnerDisplayName
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days' 
        AND ph.PostHistoryTypeId IN (10, 11, 12) -- close, reopen, delete
), 
TopUserPosts AS (
    SELECT 
        rp.PostId,
        COUNT(DISTINCT u.Id) AS ActiveUsers,
        AVG(rp.ViewCount) AS AverageViews
    FROM 
        RankedPosts rp
    JOIN 
        Votes v ON rp.PostId = v.PostId
    JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        rp.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostsCount,
    up.CommentsCount,
    up.TotalBounties,
    pp.PostId,
    pp.Title,
    pp.Rank,
    pp.AverageViews,
    rph.CreationDate AS RecentActionDate,
    rph.PostHistoryTypeId,
    rph.OwnerDisplayName
FROM 
    UserActivity up
JOIN 
    TopUserPosts pp ON up.PostsCount > 5
JOIN 
    RecentPostHistory rph ON pp.PostId = rph.PostId
ORDER BY 
    up.TotalBounties DESC, pp.Rank ASC;
