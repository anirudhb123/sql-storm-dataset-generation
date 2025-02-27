WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(Ans.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts Ans ON P.Id = Ans.ParentId
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.Score, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%<' || T.TagName || '>%'
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        T.TagName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.Score,
    RP.AnswerCount,
    TS.TagName,
    TS.PostCount,
    TS.TotalScore
FROM 
    RankedPosts RP
JOIN 
    TagStats TS ON RP.Tags LIKE '%<' || TS.TagName || '>%'
WHERE 
    RP.rn = 1 -- Selecting each question only once after ranking
ORDER BY 
    RP.Score DESC, 
    TS.TotalScore DESC
LIMIT 10; -- Top 10 questions based on score and tag performance

