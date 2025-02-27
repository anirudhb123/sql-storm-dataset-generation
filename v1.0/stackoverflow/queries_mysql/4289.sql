
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2),
            0
        ) AS UpvoteCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3),
            0
        ) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
PostStatistics AS (
    SELECT 
        r.OwnerDisplayName,
        COUNT(r.PostId) AS TotalPosts,
        SUM(r.UpvoteCount) AS TotalUpvotes,
        SUM(r.DownvoteCount) AS TotalDownvotes,
        AVG(r.Score) AS AvgScore,
        SUM(CASE WHEN r.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN r.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        RankedPosts r
    GROUP BY 
        r.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.AvgScore,
    CASE 
        WHEN ps.TotalPosts > 0 THEN ps.TotalUpvotes / ps.TotalPosts 
        ELSE 0 
    END AS UpvoteRatio,
    CASE 
        WHEN ps.TotalPosts > 0 THEN ps.TotalDownvotes / ps.TotalPosts 
        ELSE 0 
    END AS DownvoteRatio,
    (SELECT GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name ASC SEPARATOR ', ') FROM PostTypes pt 
     JOIN Posts p ON p.PostTypeId = pt.Id 
     WHERE p.OwnerUserId = (SELECT MIN(u.Id) FROM Users u WHERE u.DisplayName = ps.OwnerDisplayName)
    ) AS PostTypes
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalPosts DESC
LIMIT 10;
