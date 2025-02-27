WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularQuestions,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Questions only
    GROUP BY 
        U.Id
),
FinalResults AS (
    SELECT 
        U.DisplayName,
        U.QuestionCount,
        U.PopularQuestions,
        U.TotalAnswers,
        U.TotalComments,
        U.TotalUpVotes,
        U.TotalDownVotes,
        T.TagName
    FROM 
        UserActivity U
    JOIN 
        TopTags T ON T.Rank <= 5 -- Get top 5 tags
    ORDER BY 
        U.PopularQuestions DESC,
        U.TotalAnswers DESC
)

SELECT 
    DisplayName,
    QuestionCount,
    PopularQuestions,
    TotalAnswers,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    STRING_AGG(TagName, ', ') AS AssociatedTags
FROM 
    FinalResults
GROUP BY 
    DisplayName, QuestionCount, PopularQuestions, TotalAnswers, TotalComments, TotalUpVotes, TotalDownVotes
ORDER BY 
    PopularQuestions DESC
LIMIT 10;
