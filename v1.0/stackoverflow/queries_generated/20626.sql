WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
       	pt.Name AS PostType,
        DENSE_RANK() OVER(PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(b.Class::int) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId   
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 0
),
PostDetails AS (
    SELECT 
        hp.PostId,
        S.name AS HistoryType,
        hp.CreationDate AS HistoryDate,
        hp.UserId,
        hp.Comment
    FROM 
        PostHistory hp
    JOIN 
        PostHistoryTypes S ON hp.PostHistoryTypeId = S.Id
    WHERE 
        hp.CreationDate >= '2023-01-01'
        AND hp.UserId IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        us.TotalPosts,
        us.TotalComments,
        us.TotalBadges,
        us.TotalBounty
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.PostId = us.UserId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pp.Title AS MostEngagedPostTitle,
    pp.Score AS PostScore,
    up.DisplayName AS TopUser,
    up.TotalPosts AS UserPostCount,
    up.TotalBounty AS UserTotalBounty,
    ph.HistoryType AS LastHistoryAction,
    ph.HistoryDate AS LastHistoryDate
FROM 
    TopPosts pp
JOIN 
    Users up ON pp.UserId = up.Id
LEFT JOIN 
    PostDetails ph ON pp.PostId = ph.PostId
WHERE 
    ph.HistoryDate = (SELECT MAX(HistoryDate) FROM PostDetails WHERE PostId = pp.PostId)
ORDER BY 
    pp.Score DESC,
    up.TotalBounty DESC
LIMIT 5;

