WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
), 
PostRating AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        (P.Score * 1.0 / NULLIF(P.ViewCount, 0)) AS ScorePerView,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY (P.Score * 1.0 / NULLIF(P.ViewCount, 0)) DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.ViewCount IS NOT NULL
), 
BadgedUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS UserPostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), 
TopPosts AS (
    SELECT 
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Title IS NOT NULL AND 
        P.Title NOT LIKE '%[duplicate]%'
    ORDER BY P.Score DESC
)
SELECT 
    UVS.UserId,
    UVS.DisplayName,
    UVS.TotalUpVotes,
    UVS.TotalDownVotes,
    BUP.BadgeCount,
    BUP.UserPostCount,
    BUP.TotalScore,
    TOP.Title AS TopPostTitle,
    TOP.Score AS TopPostScore,
    TOP.ViewCount AS TopPostViewCount,
    CASE 
        WHEN TOP.PostRank <= 10 THEN 'Top 10 Posts' 
        ELSE 'Outside Top 10' 
    END AS RankingCategory
FROM 
    UserVoteStats UVS
JOIN 
    BadgedUserPosts BUP ON UVS.UserId = BUP.UserId
LEFT JOIN 
    TopPosts TOP ON UVS.UserId = TOP.OwnerUserId
WHERE 
    (TOP.Score IS NOT NULL OR UVS.TotalUpVotes > UVS.TotalDownVotes) 
    AND UVS.TotalPosts > 5
ORDER BY 
    BUP.TotalScore DESC, 
    UVS.TotalUpVotes DESC, 
    UVS.TotalDownVotes;

### Explanation:
1. **Common Table Expressions (CTEs)**: 
    - `UserVoteStats`: Calculates total upvotes and downvotes for each user, along with the number of posts they have made.
    - `PostRating`: Computes a score per view for posts while ranking them by owner.
    - `BadgedUserPosts`: Calculates number of badges and scores from posts made by users.
    - `TopPosts`: Selects and ranks the top posts based on score while avoiding duplicates.

2. **Main Query**: Combines results from the CTEs to generate a comprehensive report showing users, their voting statistics, badge count, and their top post's rank.

3. **NULL Handling**: Uses `NULLIF` to avoid division by zero when calculating scores per view.

4. **Case Logic**: Categorizes posts based on their ranking to differentiate between top and non-top posts.

5. **Complex Filtering**: Filters users based on vote differences, number of posts, and score, showcasing how intricate logic can be used to refine results. 

This query captures the complexity expected in a true benchmarking scenario, emphasizing various SQL constructs while dealing with potential edge cases.
