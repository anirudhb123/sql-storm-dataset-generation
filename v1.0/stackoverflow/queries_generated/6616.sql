WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        MAX(U.CreationDate) AS AccountCreated,
        SUM(COALESCE(V.UserId, 0)) AS TotalVotes,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AcceptedAnswers,
        TotalVotes,
        TotalViews,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.QuestionCount,
    T.AnswerCount,
    T.AcceptedAnswers,
    T.TotalVotes,
    T.TotalViews,
    AVG(EXTRACT(EPOCH FROM (P.LastActivityDate - U.CreationDate))) AS AvgPostAgeInSeconds
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    T.PostRank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.TotalPosts, T.QuestionCount, T.AnswerCount, T.AcceptedAnswers, T.TotalVotes, T.TotalViews
ORDER BY 
    T.PostRank;
