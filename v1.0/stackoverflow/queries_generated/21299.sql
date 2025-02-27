WITH RankedPosts AS (
    SELECT 
        P.Id AS PostID,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RankScore,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days' -- recent posts only
),
UserStatistics AS (
    SELECT 
        U.Id AS UserID,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AverageViewCount 
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
FilteredPosts AS (
    SELECT 
        RP.*,
        US.PostCount AS UserPostCount,
        US.BadgeCount,
        CASE 
            WHEN US.Reputation > 1000 THEN 'High Reputation User'
            WHEN US.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation User'
            ELSE 'Low Reputation User'
        END AS UserReputationCategory
    FROM 
        RankedPosts RP
    LEFT JOIN 
        UserStatistics US ON RP.OwnerUserId = US.UserID
    WHERE 
        RP.RankScore <= 5 -- top 5 posts per type
),
InactivityWarning AS (
    SELECT 
        OwnerUserId,
        MAX(LastActivityDate) AS LastActive,
        COUNT(*) AS InactivePosts
    FROM 
        Posts 
    WHERE 
        LastActivityDate < NOW() - INTERVAL '90 days'
    GROUP BY 
        OwnerUserId
)
SELECT 
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.UpVoteCount,
    FP.DownVoteCount,
    FP.CommentCount,
    FP.UserReputationCategory,
    US.DisplayName,
    ISNULL(IW.InactivePosts, 0) AS InactivePostCount,
    CASE 
        WHEN IW.LastActive IS NOT NULL THEN 'Inactive User'
        ELSE 'Active User'
    END AS UserActivityStatus
FROM 
    FilteredPosts FP
LEFT JOIN 
    InactivityWarning IW ON FP.OwnerUserId = IW.OwnerUserId
JOIN 
    UserStatistics US ON FP.OwnerUserId = US.UserID
WHERE 
    FP.ViewCount > 50 
ORDER BY 
    FP.Score DESC, 
    FP.CreationDate DESC;

### Explanation:
1. **CTEs (Common Table Expressions)**:
   - **RankedPosts**: Ranks posts based on score and creation date, with additional subqueries to count comments and votes.
   - **UserStatistics**: Calculates statistics for users, including badge count and total score from their posts.
   - **FilteredPosts**: Filters the top 5 posts per type, categorizing users by reputation.
   - **InactivityWarning**: Identifies inactive users based on last activity, counting their inactive posts.

2. **Main Query Composition**: The main query pulls data from the filtered posts while joining user and inactivity statistics to generate a comprehensive view that includes user activity status.

3. **NULL Handling**: Used `ISNULL` to ensure inactive post counting defaults to 0.

4. **Complicated Logic**: Enhanced the output with user reputation categorization and activity status, adding complexity to the outcome.

5. **Performance Factors**: The use of ranking and multiple JOINs alongside grouping and aggregation makes this a strong candidate for performance benchmarking.

This query showcases several advanced SQL features and oddities, such as nested subqueries and conditional logic, making it an intriguing case for performance analysis.
