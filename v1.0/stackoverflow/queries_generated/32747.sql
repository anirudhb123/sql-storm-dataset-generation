WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),

TopPostStatistics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalComments,
        us.Upvotes,
        us.Downvotes,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        RankedPosts r
    JOIN 
        Users u ON u.Id = (SELECT TOP 1 OwnerUserId FROM Posts WHERE Id = r.PostId)
    JOIN 
        UserStatistics us ON us.UserId = u.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = r.PostId
    WHERE 
        r.PostRank = 1
    GROUP BY 
        r.PostId, r.Title, r.CreationDate, r.ViewCount, r.Score, us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalComments, us.Upvotes, us.Downvotes
    ORDER BY 
        r.Score DESC
)

SELECT 
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.DisplayName,
    t.Reputation,
    t.TotalPosts,
    t.TotalComments,
    t.Upvotes,
    t.Downvotes,
    t.EditCount,
    t.LastEditDate
FROM 
    TopPostStatistics t
WHERE 
    t.Score IS NOT NULL
    AND t.Reputation > 100
    AND t.Upvotes - t.Downvotes > 10
ORDER BY 
    t.Score DESC
LIMIT 50;
