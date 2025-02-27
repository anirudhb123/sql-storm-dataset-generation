
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%') 
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageReputation,
        @rank := IF(@prev_post_count = PostCount, @rank, @rank + 1) AS TagRank,
        @prev_post_count := PostCount
    FROM 
        TagStatistics,
        (SELECT @rank := 0, @prev_post_count := NULL) r
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS Contributions,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        @user_rank := IF(@prev_reputation = U.Reputation, @user_rank, @user_rank + 1) AS UserRank,
        @prev_reputation := U.Reputation
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    CROSS JOIN 
        (SELECT @user_rank := 0, @prev_reputation := NULL) r
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        U.DisplayName, U.Reputation
)
SELECT 
    PT.TagName,
    PT.PostCount,
    PT.QuestionCount,
    PT.AnswerCount,
    PT.AverageReputation,
    TU.DisplayName AS HighestContributor,
    TU.Reputation AS ContributorReputation,
    TU.Contributions AS ContributionCount
FROM 
    PopularTags PT
LEFT JOIN 
    TopUsers TU ON PT.TagRank = 1 AND TU.Contributions > 0
WHERE 
    PT.PostCount > 10 
ORDER BY 
    PT.TagRank;
