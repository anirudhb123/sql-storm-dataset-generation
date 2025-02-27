WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' -- only consider posts created in the current year
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerDisplayName, 
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5 -- consider only the top 5 posts by each user
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    OwnerDisplayName, 
    TotalComments
FROM 
    TopUsers
ORDER BY 
    TotalComments DESC
LIMIT 10; -- retrieve the top 10 users with the most comments on their top posts
