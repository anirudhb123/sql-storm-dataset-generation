WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), 
PostScoreRanking AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(PC.PostCount, 0) AS TotalPosts,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        UserPostCounts PC ON U.Id = PC.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- Consider only bounty start and close
    GROUP BY 
        U.Id
    HAVING 
        SUM(COALESCE(P.Score, 0)) > 100  -- Users with a total score greater than 100
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalBounties,
    AVG(PS.Score) as AvgPostScore,
    COUNT(DISTINCT PS.PostId) as TotalTopScoringPosts
FROM 
    TopUsers TU
LEFT JOIN 
    PostScoreRanking PS ON TU.Id = PS.OwnerUserId AND PS.ScoreRank <= 5  -- Top 5 posts
GROUP BY 
    TU.DisplayName, TU.TotalPosts, TU.TotalBounties
ORDER BY 
    TU.TotalBounties DESC, AvgPostScore DESC
LIMIT 10;
This query performs the following tasks:
1. **Recursive CTE (`UserPostCounts`)**: Counts the number of posts by each user.
2. **CTE (`PostScoreRanking`)**: Ranks posts for each user based on score for the last year.
3. **CTE (`TopUsers`)**: Gathers users with their total posts and bounties, filtering out users with a total score of 100 or less.
4. The final output combines information from these CTEs to present the top users based on the number of bounties and average score of their top posts, limiting results to the top 10.
