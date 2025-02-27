WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(C.CommentCount, 0)) AS CommentCount,
        SUM(COALESCE(V.VoteCount, 0)) AS VoteCount,
        SUM(COALESCE(BadgeCount, 0)) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS VoteCount FROM Votes GROUP BY UserId) V ON U.Id = V.UserId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        CommentCount,
        VoteCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, VoteCount DESC, Reputation DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    CommentCount,
    VoteCount,
    BadgeCount
FROM 
    RankedUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
