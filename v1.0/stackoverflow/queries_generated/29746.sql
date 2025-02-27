WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.AnswerCount, 0)) AS TotalAnswers,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags 
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    WHERE 
        Posts.PostTypeId = 1  -- Only interested in Questions
    GROUP BY 
        Tags.TagName
),
UserStats AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS QuestionsAsked,
        COUNT(DISTINCT Comments.Id) AS CommentsMade,
        SUM(Votes.VoteTypeId = 2) AS TotalUpvotes,
        SUM(Votes.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users 
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(DISTINCT PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS PostHistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalAnswers,
    T.AverageScore,
    U.DisplayName,
    U.QuestionsAsked,
    U.CommentsMade,
    U.TotalUpvotes,
    U.TotalDownvotes,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.PostHistoryTypes
FROM 
    TagStats T
JOIN 
    UserStats U ON T.PostCount > 5  -- Join to a user who has asked more than 5 questions
JOIN 
    PostHistorySummary PHS ON PHS.PostId IN (
        SELECT Id FROM Posts WHERE Tags LIKE '%' || T.TagName || '%'
    )
ORDER BY 
    T.TotalViews DESC
LIMIT 10;
