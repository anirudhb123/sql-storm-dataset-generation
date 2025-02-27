WITH RECURSIVE UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COALESCE(SUM(VB.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        (SELECT 
             U.Id AS UserId,
             SUM(BountyAmount) AS BountyAmount 
         FROM 
             Votes V 
         JOIN 
             Users U ON V.UserId = U.Id 
         WHERE 
             V.VoteTypeId = 8 -- Only BountyStart votes
         GROUP BY 
             U.Id) AS VB ON U.Id = VB.UserId
    GROUP BY 
        U.Id
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        VoteCount,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalBounty DESC) AS Rank
    FROM 
        UserEngagement
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.CommentCount,
    U.VoteCount,
    U.TotalBounty,
    CASE 
        WHEN U.TotalBounty > 100 THEN 'Gold' 
        WHEN U.TotalBounty BETWEEN 50 AND 100 THEN 'Silver' 
        ELSE 'Bronze' 
    END AS EngagementBadge,
    (SELECT MIN(P.Score) 
     FROM Posts P 
     WHERE P.OwnerUserId = U.UserId 
     AND P.Score IS NOT NULL) AS MinPostScore
FROM 
    TopUsers U
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Rank;

-- Comments on logic:
-- This query first calculates user engagement metrics (post count, comment count, vote count, total bounty) 
-- using a recursive CTE. It then ranks users based on post count and total bounty, 
-- filters the top 10 users, and assigns an engagement badge based on their total bounty. 
-- Finally, it fetches the minimum post score for the posts created by each user.
