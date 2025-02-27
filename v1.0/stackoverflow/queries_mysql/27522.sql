
WITH TagFrequency AS (
    SELECT 
        TRIM(SUBSTRING(tag, 1, 35)) AS TagName,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS tag
        FROM 
            Posts
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 
            UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 
            UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
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
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.QuestionCount,
    TU.Upvotes,
    TU.Downvotes,
    (SELECT GROUP_CONCAT(T.TagName) 
     FROM PopularTags T 
     JOIN Posts P ON FIND_IN_SET(T.TagName, TRIM(BOTH '[]' FROM REPLACE(P.Tags, '><', ','))) > 0
     WHERE 
         P.OwnerUserId = TU.UserId) AS PopularTags
FROM 
    TopUsers TU;
