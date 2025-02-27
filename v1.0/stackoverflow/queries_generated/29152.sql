WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames,
        COUNT(c.Id) AS CommentCount,
        JSON_AGG(DISTINCT b.Name) AS BadgeNames
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        SUM(COALESCE(ph.PostHistoryTypeId IS NOT NULL, 0)::int) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id
    GROUP BY 
        u.Id
),
UserPostInfo AS (
    SELECT 
        up.UserId,
        COUNT(up.PostId) AS TotalPosts,
        SUM(up.CommentCount) AS TotalComments,
        SUM(up.ViewCount) AS TotalViews,
        SUM(up.Score) AS TotalScore
    FROM 
        RankedPosts up
    GROUP BY 
        up.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UserRank,
    us.EditCount,
    COALESCE(up.TotalPosts, 0) AS TotalPosts,
    COALESCE(up.TotalComments, 0) AS TotalComments,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(up.TotalScore, 0) AS TotalScore,
    STRING_AGG(DISTINCT rp.Title, '; ') AS TopPosts
FROM 
    UserStatistics us
LEFT JOIN 
    UserPostInfo up ON us.UserId = up.UserId
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = us.UserId AND rp.RankByScore <= 5 -- Top 5 Posts by score
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.UserRank, us.EditCount
ORDER BY 
    us.UserRank;
