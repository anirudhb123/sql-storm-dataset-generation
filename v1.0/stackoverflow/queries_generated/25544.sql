WITH TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, '<>')::int[])
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.PostId) AS TotalVotes,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts + TotalComments + TotalVotes + TotalBounty AS EngagementScore
    FROM 
        UserEngagement
    ORDER BY 
        EngagementScore DESC
    LIMIT 10
),
TagPerformance AS (
    SELECT 
        T.TagName,
        TC.TotalPosts,
        TC.TotalQuestions,
        TC.TotalAnswers,
        (TC.TotalAnswers::float / NULLIF(TC.TotalPosts, 0)) * 100 AS AnswerRatio
    FROM 
        TagCounts TC
    JOIN 
        Tags T ON TC.TagName = T.TagName
    WHERE 
        TC.TotalPosts > 0
    ORDER BY 
        AnswerRatio DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS TopUser,
    U.TotalPosts, 
    U.TotalComments, 
    U.TotalVotes, 
    U.TotalBounty,
    T.TagName,
    T.TotalPosts AS TagTotalPosts,
    T.TotalQuestions AS TagTotalQuestions,
    T.TotalAnswers AS TagTotalAnswers,
    T.AnswerRatio
FROM 
    TopUsers U
JOIN 
    TagPerformance T ON T.TotalAnswers > 0
ORDER BY 
    U.EngagementScore DESC, T.AnswerRatio DESC;
