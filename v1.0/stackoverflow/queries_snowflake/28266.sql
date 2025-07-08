
WITH TagStats AS (
    SELECT 
        TRIM(split_part(Tags, '><', seq)) AS Tag,
        COUNT(DISTINCT Id) AS PostCount,
        COUNT(DISTINCT OwnerUserId) AS UserCount
    FROM 
        Posts
    JOIN 
        (SELECT ROW_NUMBER() OVER() AS seq FROM TABLE(generator(ROWCOUNT => 100))) AS seq_table
    ON 
        seq <= ARRAY_SIZE(TRIM(split_to_array(SUBSTR(Tags, 2, LEN(Tags) - 2), '><')))
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
), ClosedQuestions AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        Posts
    JOIN 
        PostHistory PH ON Posts.Id = PH.PostId
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate
), PopularTags AS (
    SELECT
        TS.Tag,
        TS.PostCount,
        TS.UserCount,
        CQ.CloseCount
    FROM 
        TagStats TS
    LEFT JOIN 
        ClosedQuestions CQ ON TS.PostCount > 5 
    ORDER BY 
        TS.PostCount DESC
    LIMIT 10
)

SELECT 
    PT.Tag,
    PT.PostCount,
    PT.UserCount,
    PT.CloseCount,
    (CAST(PT.PostCount AS FLOAT) / NULLIF(PT.UserCount, 0)) AS PostsPerUser,
    (SELECT COUNT(*) FROM Posts WHERE Title ILIKE '%' || PT.Tag || '%') AS TitleMentions
FROM 
    PopularTags PT
ORDER BY 
    PT.PostCount DESC;
