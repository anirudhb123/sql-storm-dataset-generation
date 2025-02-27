WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(B.Class) AS TotalBadgeClass,
        COUNT(V.Id) AS VoteCount,
        COUNT(DISTINCT T.TagName) AS UniqueTagCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, ',')) AS T(TagName) ON TRUE
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        TotalBadgeClass,
        VoteCount,
        UniqueTagCount,
        RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC, TotalBadgeClass DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AnswerCount,
    CommentCount,
    TotalBadgeClass,
    VoteCount,
    UniqueTagCount,
    Rank
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
