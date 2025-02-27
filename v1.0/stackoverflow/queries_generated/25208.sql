WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) AS TagName,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 5 -- Select tags appearing in more than 5 questions
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.CommentCount,
        ROW_NUMBER() OVER (ORDER BY (UA.QuestionCount + UA.AnswerCount + UA.CommentCount) DESC) AS UserRank
    FROM 
        UserActivity UA
    WHERE 
        (UA.QuestionCount + UA.AnswerCount + UA.CommentCount) > 10
)
SELECT 
    U.DisplayName,
    U.UserId,
    U.QuestionCount,
    U.AnswerCount,
    U.CommentCount,
    TT.TagName,
    TT.Frequency
FROM 
    ActiveUsers U
JOIN 
    TopTags TT ON TRUE
ORDER BY 
    U.UserRank, TT.Frequency DESC;
