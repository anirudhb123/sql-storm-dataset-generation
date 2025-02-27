WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName 
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagUsage
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionsAsked,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        TotalViews DESC
    LIMIT 5
),
PostContributions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(V.VoteCount, 0) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    T.TagName,
    T.PostCount,
    U.DisplayName,
    U.QuestionsAsked,
    U.TotalAnswers,
    U.TotalViews,
    P.Title AS TopPostTitle,
    P.CommentCount,
    P.VoteCount
FROM 
    TopTags T
JOIN 
    MostActiveUsers U ON true
JOIN 
    PostContributions P ON true
WHERE 
    T.Rank <= 10 -- Top 10 Tags
ORDER BY 
    T.PostCount DESC, U.TotalViews DESC;
