WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(*) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM Posts P
    JOIN LATERAL STRING_TO_ARRAY(SUBSTR(P.Tags, 2, LENGTH(P.Tags) - 2), '><') AS TagArray ON TRUE
    JOIN Tags T ON T.TagName = TagArray
    WHERE P.PostTypeId = 1 -- Only considering questions
    GROUP BY P.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1
    LEFT JOIN Votes V ON V.PostId = P.Id
    WHERE U.Reputation > 1000 -- Considering only users with high reputation
    GROUP BY U.Id
),
PopularTags AS (
    SELECT 
        T.TagName,
        SUM(PTC.TagCount) AS TotalPosts
    FROM Tags T
    JOIN PostTagCounts PTC ON PTC.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    ORDER BY TotalPosts DESC
    LIMIT 5
)
SELECT 
    U.DisplayName,
    U.QuestionsAsked,
    U.TotalViews,
    U.Upvotes,
    U.Downvotes,
    PT.Tags AS QuestionTags
FROM TopUsers U
JOIN PostTagCounts PT ON U.QuestionsAsked > 0 -- Only considering users who asked questions
WHERE U.Upvotes > U.Downvotes
  AND EXISTS (SELECT 1 FROM PopularTags P WHERE P.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(PT.Tags, ', '))))
ORDER BY U.TotalViews DESC
LIMIT 10;
