
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        U.DisplayName AS Author,
        P.Tags,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory ph ON P.Id = ph.PostId 
                        AND ph.CreationDate = (SELECT MAX(ph2.CreationDate) 
                                                FROM PostHistory ph2 
                                                WHERE ph2.PostId = P.Id) 
    WHERE 
        P.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
        AND P.PostTypeId = 1 
),

TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts P
    INNER JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        P.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
        AND P.PostTypeId = 1
    GROUP BY 
        TagName
),

TagStatistics AS (
    SELECT 
        T.TagName,
        T.Count AS TotalPosts,
        COALESCE(TU.UsageCount, 0) AS UsedInQuestions,
        COALESCE(CAST(TU.UsageCount AS DECIMAL) / NULLIF(T.Count, 0), 0) * 100 AS UsagePercentage
    FROM 
        Tags T
    LEFT JOIN 
        TagUsage TU ON T.TagName = TU.TagName
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.Author,
    PD.ViewCount,
    PD.Score,
    PD.LastEditor,
    PD.LastEditDate,
    TS.TagName,
    TS.TotalPosts,
    TS.UsedInQuestions,
    TS.UsagePercentage
FROM 
    PostDetails PD
JOIN 
    TagStatistics TS ON FIND_IN_SET(TS.TagName, PD.Tags) > 0
ORDER BY 
    PD.Score DESC, 
    PD.ViewCount DESC;
