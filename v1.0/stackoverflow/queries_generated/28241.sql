WITH TagCounts AS (
    SELECT 
        TRIM(unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')))::varchar) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Questions only
    GROUP BY 
        TRIM(unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')))
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionsAnswered,
        COUNT(DISTINCT C.Id) AS CommentsMade
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.Tag, 
        TC.PostCount,
        ROW_NUMBER() OVER (ORDER BY TC.PostCount DESC) AS TagRank
    FROM 
        TagCounts TC
    JOIN 
        Tags T ON T.TagName = TC.Tag
    WHERE 
        TC.PostCount > 5  -- Only consider popular tags
),
TopUsers AS (
    SELECT 
        U.UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.QuestionsAnswered, 
        U.CommentsMade
    FROM 
        UserReputation U
    JOIN 
        PopularTags PT ON PT.Tag = ANY(string_to_array(substring((SELECT Tags FROM Posts WHERE PostTypeId = 1 LIMIT 1), 2, length(Tags)-2), '><'))
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    PT.Tag,
    PT.PostCount
FROM 
    TopUsers TU
JOIN 
    PopularTags PT ON PT.Tag IN (
        SELECT 
            TRIM(unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')))::varchar)
        FROM 
            Posts
        WHERE 
            OwnerUserId = TU.UserId
        AND 
            PostTypeId = 1  -- Considering only questions
    )
ORDER BY 
    PT.PostCount DESC, 
    TU.Reputation DESC;
