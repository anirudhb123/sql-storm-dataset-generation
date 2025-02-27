-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiCount,
        SUM(COALESCE(V.Score, 0)) AS TotalVotes,
        MIN(U.CreationDate) AS UserSince,
        MAX(P.LastActivityDate) AS LastActive
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TagWikiCount,
    U.TotalVotes,
    U.UserSince,
    U.LastActive,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.TotalViews
FROM 
    UserStats U
CROSS JOIN 
    PopularTags T;

