WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Location,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate ASC) AS RN
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Location
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        QuestionCount, 
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        RN = 1
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    GROUP BY 
        T.TagName
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN P.CreationDate > (NOW() - INTERVAL '30 days') THEN 1 END) AS RecentPostCount,
        COUNT(CASE WHEN C.CreationDate > (NOW() - INTERVAL '30 days') THEN 1 END) AS RecentCommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    U.UserRank,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.UpVoteCount,
    U.DownVoteCount,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.QuestionCount AS TagQuestionCount,
    T.AnswerCount AS TagAnswerCount,
    R.RecentPostCount,
    R.RecentCommentCount
FROM 
    TopUsers U
LEFT JOIN 
    TagStats T ON U.UserId = T.TagName
LEFT JOIN 
    RecentActivity R ON U.UserId = R.UserId
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.UserRank;
