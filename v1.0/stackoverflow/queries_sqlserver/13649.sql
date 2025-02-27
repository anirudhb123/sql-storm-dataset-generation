
WITH PostCounts AS (
    SELECT 
        FORMAT(CreationDate, 'yyyy-MM-01') AS Month,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        FORMAT(CreationDate, 'yyyy-MM-01')
),
UserCounts AS (
    SELECT 
        FORMAT(CreationDate, 'yyyy-MM-01') AS Month,
        COUNT(*) AS TotalUsers
    FROM 
        Users
    GROUP BY 
        FORMAT(CreationDate, 'yyyy-MM-01')
),
VoteCounts AS (
    SELECT 
        FORMAT(CreationDate, 'yyyy-MM-01') AS Month,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        FORMAT(CreationDate, 'yyyy-MM-01')
)

SELECT 
    COALESCE(pc.Month, uc.Month, vc.Month) AS Month,
    COALESCE(pc.TotalPosts, 0) AS TotalPosts,
    COALESCE(uc.TotalUsers, 0) AS TotalUsers,
    COALESCE(vc.TotalVotes, 0) AS TotalVotes
FROM 
    PostCounts pc
FULL OUTER JOIN 
    UserCounts uc ON pc.Month = uc.Month
FULL OUTER JOIN 
    VoteCounts vc ON pc.Month = vc.Month
ORDER BY 
    Month;
