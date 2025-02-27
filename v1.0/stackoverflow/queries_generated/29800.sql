WITH TagCount AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        Tag
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
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
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
    TopUsers U ON U.UserRank <= 10 -- Top 10 users
WHERE 
    T.Tag IN (
        SELECT 
            Tag 
        FROM 
            TopTags 
        WHERE 
            TagRank <= 5 -- Top 5 tags
    )
ORDER BY 
    T.PostCount DESC, U.TotalUpVotes DESC;
