WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only focus on questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rnk
    FROM 
        TagFrequency
    WHERE 
        TagCount > 5 -- Only include tags used in more than 5 questions
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Votes.VoteTypeId = 2) AS UpVoteCount,
        SUM(Votes.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS Rnk
    FROM 
        UserActivity
    WHERE 
        QuestionCount > 0
)
SELECT 
    T.TagName,
    T.TagCount,
    U.DisplayName AS TopUser,
    U.QuestionCount,
    U.AnswerCount,
    U.UpVoteCount,
    U.DownVoteCount
FROM 
    TopTags T
JOIN 
    TopUsers U ON T.TagCount = (
        SELECT MAX(TagCount) 
        FROM TopTags WHERE TagCount <= (SELECT TagCount FROM TopTags WHERE Rnk <= 10)
    )
ORDER BY 
    T.TagCount DESC, U.QuestionCount DESC
LIMIT 10;
