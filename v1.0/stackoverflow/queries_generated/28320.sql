WITH TagPostCounts AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%' )  -- Assuming Tags are delimited by < and > in the Tags column
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) as TagRank
    FROM 
        TagPostCounts
    WHERE 
        PostCount > 0
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.VoteTypeId = 2) AS UpVotes,  -- Count of upvotes
        SUM(V.VoteTypeId = 3) AS DownVotes,  -- Count of downvotes
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS Score,
        QuestionsAsked,
        AnswersGiven,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    T.TagName,
    T.PostCount,
    U.DisplayName,
    U.Score,
    U.QuestionsAsked,
    U.AnswersGiven
FROM 
    PopularTags T
JOIN 
    TopUsers U ON T.TagRank = U.UserRank
WHERE 
    U.UserRank <= 10  -- Get top 10 users
ORDER BY 
    T.TagCount DESC,  -- Order by most popular tags
    U.Score DESC;  -- Then by user score
