WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only count tags from questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 10  -- Limit to tags used in more than 10 posts
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        QuestionCount > 5  -- Consider only users with more than 5 questions
)
SELECT 
    T.Tag,
    T.PostCount,
    U.DisplayName,
    U.QuestionCount,
    U.UpvoteCount,
    U.DownvoteCount 
FROM 
    TopTags T
JOIN 
    MostActiveUsers U ON T.Tag = ANY(SELECT unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')) FROM Posts WHERE OwnerUserId = U.UserId AND PostTypeId = 1)
ORDER BY 
    T.PostCount DESC, U.QuestionCount DESC;
