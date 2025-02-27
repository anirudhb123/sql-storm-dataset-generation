WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.AnswerCount) AS TotalAnswers,
        AVG(P.ViewCount) AS AverageViews,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadgesEarned,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ContributingUsers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalAnswers,
        AverageViews,
        TotalComments,
        TotalBadgesEarned,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    TotalAnswers,
    AverageViews,
    TotalComments,
    TotalBadgesEarned
FROM 
    TopTags
WHERE 
    TagRank <= 10 -- Top 10 tags by number of questions
ORDER BY 
    PostCount DESC;
