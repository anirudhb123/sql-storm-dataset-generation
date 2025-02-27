WITH UserInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgPostScore,
        MAX(P.CreationDate) AS LatestPost
    FROM 
        Tags T
    JOIN PostTags PT ON T.Id = PT.TagId
    JOIN Posts P ON PT.PostId = P.Id
    GROUP BY 
        T.TagName
),

HighlyRatedTags AS (
    SELECT 
        TagName,
        TotalViews,
        AvgPostScore,
        ROW_NUMBER() OVER (ORDER BY AvgPostScore DESC, TotalViews DESC) AS Rank
    FROM 
        TagUsage
    WHERE 
        PostCount > 10 AND AvgPostScore > 10
)

SELECT 
    UI.UserId,
    UI.DisplayName,
    UI.Reputation,
    COALESCE(HT.TagName, 'No Highly Rated Tag') AS HighlyRatedTag,
    COALESCE(HT.TotalViews, 0) AS TotalViews,
    COALESCE(HT.AvgPostScore, 0) AS AvgPostScore,
    UI.TotalPosts,
    UI.TotalComments,
    UI.UpVotes,
    UI.DownVotes,
    UI.TotalBadges
FROM 
    UserInteractions UI
LEFT JOIN 
    HighlyRatedTags HT ON UI.UserId = (
       SELECT TOP 1 U.Id 
       FROM Users U 
       JOIN Posts P ON U.Id = P.OwnerUserId 
       JOIN PostTags PT ON P.Id = PT.PostId 
       JOIN Tags T ON T.Id = PT.TagId 
       WHERE T.TagName = HT.TagName
       ORDER BY P.Score DESC
    )
ORDER BY 
    UI.Reputation DESC, 
    UI.TotalPosts DESC;

-- Explanation of the query:
-- 1. The first CTE (UserInteractions) aggregates data related to user posts, comments, votes, and badges.
-- 2. The second CTE (TagUsage) aggregates statistics about tags and their associated posts.
-- 3. The third CTE (HighlyRatedTags) filters tags to find those with a significant number of posts and high average scores.
-- 4. The main query resolves user information in conjunction with their highest-rated tags, or indicates 'No Highly Rated Tag' if none exists.
-- 5. It uses a correlated subquery to join the users with their highest-rated tag based on post scores.

