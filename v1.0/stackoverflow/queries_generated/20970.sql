WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only recent questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(p.Score) AS AvgPostScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS IsDeleted,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score AS PostScore,
    up.ViewCount AS PostViewCount,
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.AvgPostScore,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes,
    ph.IsClosed,
    ph.IsDeleted,
    ph.EditCount,
    CASE 
        WHEN ph.IsClosed = 1 THEN 'Closed'
        WHEN ph.IsDeleted = 1 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN up.UserRank = 1 THEN 'Top Post'
        WHEN up.CommentCount > 5 THEN 'Popular'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    RankedPosts up
JOIN 
    UserStats us ON up.OwnerUserId = us.UserId
JOIN 
    PostHistoryStats ph ON up.PostId = ph.PostId
WHERE 
    us.Reputation >= 1000 -- Only consider influential users
ORDER BY 
    up.Score DESC,
    us.Reputation DESC
LIMIT 10;

