
WITH TagCount AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCount
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
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM 
        UserActivity
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
