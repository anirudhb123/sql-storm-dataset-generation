
WITH PostCounts AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        DATE_FORMAT(CreationDate, '%Y-%m-01')
),
UserCounts AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalUsers
    FROM 
        Users
    GROUP BY 
        DATE_FORMAT(CreationDate, '%Y-%m-01')
),
VoteCounts AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        DATE_FORMAT(CreationDate, '%Y-%m-01')
)

SELECT 
    COALESCE(pc.Month, uc.Month, vc.Month) AS Month,
    COALESCE(pc.TotalPosts, 0) AS TotalPosts,
    COALESCE(uc.TotalUsers, 0) AS TotalUsers,
    COALESCE(vc.TotalVotes, 0) AS TotalVotes
FROM 
    PostCounts pc
LEFT JOIN 
    UserCounts uc ON pc.Month = uc.Month
LEFT JOIN 
    VoteCounts vc ON pc.Month = vc.Month
UNION
SELECT 
    COALESCE(pc.Month, uc.Month, vc.Month) AS Month,
    COALESCE(pc.TotalPosts, 0) AS TotalPosts,
    COALESCE(uc.TotalUsers, 0) AS TotalUsers,
    COALESCE(vc.TotalVotes, 0) AS TotalVotes
FROM 
    UserCounts uc
LEFT JOIN 
    PostCounts pc ON pc.Month = uc.Month
LEFT JOIN 
    VoteCounts vc ON pc.Month = vc.Month
WHERE pc.Month IS NULL
UNION
SELECT 
    COALESCE(pc.Month, uc.Month, vc.Month) AS Month,
    COALESCE(pc.TotalPosts, 0) AS TotalPosts,
    COALESCE(uc.TotalUsers, 0) AS TotalUsers,
    COALESCE(vc.TotalVotes, 0) AS TotalVotes
FROM 
    VoteCounts vc
LEFT JOIN 
    PostCounts pc ON pc.Month = vc.Month
LEFT JOIN 
    UserCounts uc ON uc.Month = vc.Month
WHERE pc.Month IS NULL AND uc.Month IS NULL
ORDER BY 
    Month;
