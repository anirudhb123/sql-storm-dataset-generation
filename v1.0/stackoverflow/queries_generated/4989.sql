WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(V.CreationDate) AS AvgVoteDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)
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
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    COALESCE(AVG(B.Date), 'No Badges') AS AvgBadgeDate,
    COUNT(C.Id) AS CommentCount
FROM 
    TopUsers TU
LEFT JOIN 
    Badges B ON TU.UserId = B.UserId
LEFT JOIN 
    Comments C ON C.UserId = TU.UserId
WHERE 
    TU.PostRank <= 10
GROUP BY 
    TU.UserId, TU.DisplayName, TU.TotalPosts, TU.QuestionCount, TU.AnswerCount
ORDER BY 
    TU.TotalPosts DESC;
