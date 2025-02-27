WITH TagCounts AS (
    SELECT 
        "Tags", 
        UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag 
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagAggregates AS (
    SELECT 
        Tag, 
        COUNT(*) AS PostCount 
    FROM 
        TagCounts 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagAggregates
    WHERE 
        PostCount > 10
),
UserActivities AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS PostsCreated, 
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswersGiven,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotesReceived,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
UserTopTags AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        T.Tag,
        T.PostCount,
        RANK() OVER (PARTITION BY U.UserId ORDER BY T.PostCount DESC) AS TagRank
    FROM 
        UserActivities U
    JOIN 
        TopTags T ON U.PostsCreated > 5
),
FinalResults AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.PostsCreated,
        U.AnswersGiven,
        U.UpVotesReceived,
        U.DownVotesReceived,
        T.Tag,
        T.PostCount AS TagPostCount
    FROM 
        UserActivities U
    JOIN 
        UserTopTags T ON U.UserId = T.UserId
    WHERE 
        T.TagRank <= 5
)
SELECT 
    UserId,
    DisplayName,
    PostsCreated,
    AnswersGiven,
    UpVotesReceived,
    DownVotesReceived,
    STRING_AGG(Tag || ' (' || TagPostCount || ')', ', ') AS TopTags
FROM 
    FinalResults
GROUP BY 
    UserId, DisplayName, PostsCreated, AnswersGiven, UpVotesReceived, DownVotesReceived
ORDER BY 
    PostsCreated DESC;
