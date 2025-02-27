-- Performance benchmarking query to retrieve user statistics along with their top posts
WITH TopPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COUNT(DISTINCT bp.PostId) AS TotalPosts,
    SUM(bp.Score) AS TotalScore,
    MAX(bp.CreationDate) AS LastPostDate,
    STRING_AGG(tp.Title, ', ') AS TopPostTitles
FROM 
    Users u
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId AND tp.Rank <= 3 -- Get top 3 posts
LEFT JOIN 
    Posts bp ON u.Id = bp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
ORDER BY 
    u.Reputation DESC;
