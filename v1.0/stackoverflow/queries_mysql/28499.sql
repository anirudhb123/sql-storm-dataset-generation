
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', numbers.n), '> <', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '> <', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        @row_num := @row_num + 1 AS Rank
    FROM 
        TagCounts, (SELECT @row_num := 0) AS r
    ORDER BY 
        PostCount DESC
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularQuestions,
        SUM(IFNULL(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(IFNULL(P.CommentCount, 0)) AS TotalComments,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
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
        TopTags T ON T.Rank <= 5 
)

SELECT 
    DisplayName,
    QuestionCount,
    PopularQuestions,
    TotalAnswers,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    GROUP_CONCAT(TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    FinalResults
GROUP BY 
    DisplayName, QuestionCount, PopularQuestions, TotalAnswers, TotalComments, TotalUpVotes, TotalDownVotes
ORDER BY 
    PopularQuestions DESC
LIMIT 10;
