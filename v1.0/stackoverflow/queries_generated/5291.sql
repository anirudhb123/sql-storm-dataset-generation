WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only considering Questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, OwnerDisplayName, CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 -- Top 5 posts per user
)
SELECT 
    tr.OwnerDisplayName,
    COUNT(DISTINCT tr.PostId) AS TotalTopPosts,
    AVG(tr.Score) AS AverageScore,
    SUM(tr.CommentCount) AS TotalComments
FROM 
    TopRankedPosts tr
GROUP BY 
    tr.OwnerDisplayName
HAVING 
    COUNT(DISTINCT tr.PostId) > 1 -- More than one top post
ORDER BY 
    TotalTopPosts DESC, AverageScore DESC
LIMIT 10; -- Limit to top 10 users
