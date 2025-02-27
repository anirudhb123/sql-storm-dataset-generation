
WITH UserRank AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(P.AcceptedAnswerId IS NOT NULL, FALSE) AS IsAccepted,
        T.TagName,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 
               UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1) AS T ON TRUE
    WHERE 
        P.PostTypeId = 1 
),
MostActiveUsers AS (
    SELECT 
        PostSummary.OwnerDisplayName,
        COUNT(PostSummary.PostId) AS QuestionCount,
        SUM(PostSummary.ViewCount) AS TotalViews,
        SUM(PostSummary.AnswerCount) AS TotalAnswers,
        R.UserRank
    FROM 
        PostSummary
    JOIN 
        UserRank R ON PostSummary.OwnerDisplayName = R.DisplayName
    GROUP BY 
        PostSummary.OwnerDisplayName, R.UserRank
),
TopActiveUsers AS (
    SELECT 
        OwnerDisplayName,
        QuestionCount,
        TotalViews,
        TotalAnswers,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalViews DESC) AS ActivityRank
    FROM 
        MostActiveUsers
)
SELECT 
    OwnerDisplayName,
    QuestionCount,
    TotalViews,
    TotalAnswers,
    ActivityRank
FROM 
    TopActiveUsers
WHERE 
    ActivityRank <= 10
ORDER BY 
    ActivityRank;
