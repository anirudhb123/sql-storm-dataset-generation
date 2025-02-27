WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Filtering only questions for tag extraction
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        TagsSplit 
    GROUP BY 
        Tag 
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
QuestionAnalytics AS (
    SELECT 
        P.Title,
        P.ViewCount,
        P.Score,
        T.Tag,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        UR.BadgeCount
    FROM 
        Posts P
    JOIN 
        TagsSplit T ON P.Id = T.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        T.Tag IN (SELECT Tag FROM PopularTags)
    ORDER BY 
        P.ViewCount DESC
)
SELECT 
    * 
FROM 
    QuestionAnalytics
LIMIT 20;  -- Limiting final output for easier readability

This SQL query benchmarks string processing by extracting and analyzing tags from question posts. It involves the following steps:

1. `TagsSplit`: Splits the Tags string from Posts where PostTypeId is 1 (Questions) into separate rows.
2. `UserReputation`: Aggregates user data including their reputation and badge counts from the Badges table.
3. `PopularTags`: Identifies the 10 most popular tags based on their occurrences in the Questions.
4. `QuestionAnalytics`: Joins all previous CTEs to gather detailed analytics on questions that include these popular tags, including the titles, view counts, scores, and owner reputation alongside their badge counts.
5. Finally, it selects the top 20 results for readability.
