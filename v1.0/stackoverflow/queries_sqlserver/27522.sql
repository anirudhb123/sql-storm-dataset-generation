
WITH TagFrequency AS (
    SELECT 
        RTRIM(SUBSTRING(tag, 1, 35)) AS TagName,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            value AS tag
        FROM 
            Posts
        CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
        WHERE 
            PostTypeId = 1 
    ) AS TagList
    GROUP BY 
        TagName
),
PopularTags AS (
    SELECT 
        TagName 
    FROM 
        TagFrequency 
    WHERE 
        Frequency > (
            SELECT 
                AVG(Frequency) 
            FROM 
                TagFrequency
        )
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionCount,
        UA.Upvotes,
        UA.Downvotes
    FROM 
        UserActivity UA
    WHERE 
        UA.QuestionCount > 5
    ORDER BY 
        UA.Upvotes DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    TU.DisplayName,
    TU.QuestionCount,
    TU.Upvotes,
    TU.Downvotes,
    (SELECT STRING_AGG(T.TagName, ',') 
     FROM PopularTags T 
     JOIN Posts P ON T.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><'))
     WHERE 
         P.OwnerUserId = TU.UserId) AS PopularTags
FROM 
    TopUsers TU;
