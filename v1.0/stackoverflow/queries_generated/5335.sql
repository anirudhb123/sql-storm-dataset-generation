WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Title,
        u.DisplayName AS Owner,
        rp.Rank,
        COALESCE(SUM(c.Score), 0) AS TotalComments,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes,
        COALESCE(SUM(b.Class = 1), 0) AS TotalGoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS TotalSilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS TotalBronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON p.Id = rp.PostId
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        p.PostId, p.Title, u.DisplayName, rp.Rank
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Owner,
    ps.Rank,
    ps.TotalComments,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.TotalGoldBadges,
    ps.TotalSilverBadges,
    ps.TotalBronzeBadges
FROM 
    PostStatistics ps
JOIN 
    TopUsers tu ON ps.Owner = tu.DisplayName
WHERE 
    ps.Rank <= 5
ORDER BY 
    ps.Rank, ps.TotalUpvotes DESC;
