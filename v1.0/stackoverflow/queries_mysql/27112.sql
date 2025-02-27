
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b 
         ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rank := IF(@prev_postcount = PostCount, @rank, @rank + 1) AS TagRank,
        @prev_postcount := PostCount
    FROM 
        TagCounts, (SELECT @rank := 0, @prev_postcount := NULL) r
    ORDER BY 
        PostCount DESC
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(IFNULL(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100  
    GROUP BY 
        U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalAnswers,
        UpVotes,
        DownVotes,
        @user_rank := IF(@prev_questioncount = QuestionCount, @user_rank, @user_rank + 1) AS UserRank,
        @prev_questioncount := QuestionCount
    FROM 
        UserStats, (SELECT @user_rank := 0, @prev_questioncount := NULL) r
    WHERE 
        QuestionCount > 5  
)
SELECT 
    TT.TagName,
    TT.PostCount,
    PU.DisplayName,
    PU.QuestionCount,
    PU.TotalAnswers,
    PU.UpVotes,
    PU.DownVotes
FROM 
    TopTags TT
JOIN 
    PopularUsers PU ON TT.TagName LIKE CONCAT('%', PU.DisplayName, '%') 
WHERE 
    TT.TagRank <= 10  
ORDER BY 
    TT.PostCount DESC, PU.QuestionCount DESC;
