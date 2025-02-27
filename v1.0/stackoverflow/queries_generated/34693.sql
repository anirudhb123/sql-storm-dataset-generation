WITH RecursiveTagUsage AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        Tags.TagName
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
), 
UserRanking AS (
    SELECT 
        UserId,
        DisplayName,
        TotalAnswers,
        TotalComments,
        TotalPosts,
        TotalBounty,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank,
        RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM 
        UserActivity
),
RecentActivity AS (
    SELECT 
        U.DisplayName,
        MAX(COALESCE(P.CreationDate, C.CreationDate)) AS LastActivityDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.DisplayName
)
SELECT 
    T.TagName,
    T.PostCount,
    UR.DisplayName,
    UR.TotalPosts,
    UR.TotalAnswers,
    UR.TotalComments,
    UR.TotalBounty,
    UR.AnswerRank,
    UR.BountyRank,
    UR.CommentRank,
    RA.LastActivityDate
FROM 
    RecursiveTagUsage T
LEFT JOIN 
    UserRanking UR ON UR.TotalPosts > 0
LEFT JOIN 
    RecentActivity RA ON RA.DisplayName = UR.DisplayName
WHERE 
    T.PostCount > 5
ORDER BY 
    T.PostCount DESC, 
    UR.TotalAnswers DESC;
