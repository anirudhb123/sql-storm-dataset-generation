
WITH UserAggregate AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        Upvotes,
        Downvotes,
        @row_number_upvotes := IF(@prev_upvotes = Upvotes, @row_number_upvotes, @row_number_upvotes + 1) AS UpvoteRank,
        @prev_upvotes := Upvotes,
        @row_number_posts := IF(@prev_posts = TotalPosts, @row_number_posts, @row_number_posts + 1) AS PostRank,
        @prev_posts := TotalPosts
    FROM 
        UserAggregate,
        (SELECT @row_number_upvotes := 0, @prev_upvotes := NULL, @row_number_posts := 0, @prev_posts := NULL) AS vars
    ORDER BY 
        Upvotes DESC, TotalPosts DESC
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalAnswers,
    T.Upvotes,
    T.Downvotes,
    CASE 
        WHEN T.UpvoteRank <= 10 THEN 'Top Upvoted'
        ELSE 'Moderate Upvoted'
    END AS UpvoteCategory,
    CASE 
        WHEN T.PostRank <= 10 THEN 'Top Contributor'
        ELSE 'Moderate Contributor'
    END AS ContributionCategory,
    (SELECT GROUP_CONCAT(P.Title SEPARATOR '; ') 
     FROM Posts P 
     WHERE P.OwnerUserId = T.UserId) AS PostTitles
FROM 
    TopUsers T
WHERE 
    T.TotalPosts > 0 
ORDER BY 
    T.Upvotes DESC, T.TotalPosts DESC;
