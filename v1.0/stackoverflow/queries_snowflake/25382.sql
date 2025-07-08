
WITH TagFrequency AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            TRIM(value) AS TagName
        FROM 
            Posts,
            LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><')) 
        ) AS flattened_tags
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        PostCount > 5  
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotesCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserTagEngagement AS (
    SELECT
        UA.UserId,
        UA.UserDisplayName,
        TT.TagName,
        TT.PostCount,
        UA.QuestionCount,
        UA.UpVotesCount,
        UA.DownVotesCount
    FROM 
        UserActivity UA
    JOIN 
        Posts P ON UA.UserId = P.OwnerUserId
    JOIN 
        TopTags TT ON TT.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(SUBSTR(P.Tags, 2, LENGTH(P.Tags) - 2), '><')))
    WHERE 
        UA.QuestionCount > 0
)
SELECT 
    UserDisplayName,
    TagName,
    SUM(PostCount) AS EngagementCount,
    SUM(UpVotesCount) AS TotalUpVotes,
    SUM(DownVotesCount) AS TotalDownVotes
FROM 
    UserTagEngagement
GROUP BY 
    UserDisplayName, TagName
ORDER BY 
    EngagementCount DESC, TotalUpVotes DESC
LIMIT 10;
