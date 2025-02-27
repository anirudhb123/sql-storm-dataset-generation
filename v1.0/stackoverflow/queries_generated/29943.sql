WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1 -- Only include tags used in more than one question
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS QuestionsClosed,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 25 THEN 1 ELSE 0 END), 0) AS QuestionsTweeted
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Only questions
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.Tag,
        SUM(TC.PostCount) AS TotalUsage
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    JOIN 
        TagCounts TC ON TC.Tag = UNNEST(STRING_TO_ARRAY(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><'))
    GROUP BY 
        U.Id, U.DisplayName, T.Tag
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.QuestionsAsked,
    UA.QuestionsClosed,
    UA.QuestionsTweeted,
    STRING_AGG(UT.Tag || ' (' || UT.TotalUsage || ')', ', ') AS TagsUsed,
    T.PostCount AS Popularity
FROM 
    UserActivity UA
LEFT JOIN 
    UserTags UT ON UA.UserId = UT.UserId
LEFT JOIN 
    TopTags T ON UT.Tag = T.Tag 
GROUP BY 
    UA.UserId, UA.DisplayName, T.PostCount
ORDER BY 
    UA.QuestionsAsked DESC, TagsUsed;
