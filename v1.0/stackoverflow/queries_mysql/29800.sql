
WITH TagCount AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers, (SELECT @row := 0) r) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        @rank := IF(@prev_postcount = PostCount, @rank, @rank + 1) AS TagRank,
        @prev_postcount := PostCount
    FROM 
        TagCount, (SELECT @rank := 0, @prev_postcount := NULL) r
    ORDER BY 
        PostCount DESC
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        QuestionCount, 
        CommentCount, 
        TotalUpVotes, 
        TotalDownVotes,
        @user_rank := IF(@prev_questioncount = QuestionCount, @user_rank, @user_rank + 1) AS UserRank,
        @prev_questioncount := QuestionCount
    FROM 
        UserActivity, (SELECT @user_rank := 0, @prev_questioncount := NULL) r
)
SELECT 
    T.Tag,
    T.PostCount,
    U.DisplayName,
    U.QuestionCount,
    U.CommentCount,
    U.TotalUpVotes,
    U.TotalDownVotes
FROM 
    TopTags T
JOIN 
    TopUsers U ON U.UserRank <= 10 
WHERE 
    T.Tag IN (
        SELECT 
            Tag 
        FROM 
            TopTags 
        WHERE 
            TagRank <= 5 
    )
ORDER BY 
    T.PostCount DESC, U.TotalUpVotes DESC;
