
WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT T.TagName) AS TagCount,
        LISTAGG(DISTINCT T.TagName, ', ') WITHIN GROUP (ORDER BY T.TagName) AS Tags
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        LATERAL FLATTEN(input => SPLIT(TRIM(BOTH '{}' FROM P.Tags), '><')) AS T ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(T.TagName) AS Frequency
    FROM 
        Posts P
    JOIN 
        LATERAL FLATTEN(input => SPLIT(TRIM(BOTH '{}' FROM P.Tags), '><')) AS T ON TRUE
    GROUP BY 
        T.TagName
    ORDER BY 
        Frequency DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.PostsCreated,
        U.PostsClosed,
        UT.Tags,
        PT.TagName AS MostPopularTag
    FROM 
        UserActivity U
    JOIN 
        UserTags UT ON U.UserId = UT.UserId
    LEFT JOIN 
        PopularTags PT ON TRUE
    ORDER BY 
        U.PostsCreated DESC
)
SELECT 
    DisplayName,
    PostsCreated,
    PostsClosed,
    Tags,
    MostPopularTag
FROM 
    FinalReport
WHERE 
    MostPopularTag IS NULL;
