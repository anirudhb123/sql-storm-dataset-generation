WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Questions only
        AND P.Score >= 0  -- Only considering questions with non-negative scores
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS QuestionCount
    FROM 
        Posts P
    CROSS APPLY 
        STRING_SPLIT(P.Tags, '>') AS T  -- Split the tags into individual ones
    WHERE 
        P.PostTypeId = 1  -- Questions only
        AND P.Score >= 0  -- Only considering questions with a score
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(*) > 10  -- Only keep tags with more than 10 questions
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Tags,
        RP.Author,
        RP.CreationDate,
        RP.LastActivityDate,
        RP.Score,
        RP.ViewCount,
        PT.TagName
    FROM 
        RankedPosts RP
    INNER JOIN 
        PopularTags PT ON RP.Tags LIKE '%' + PT.TagName + '%'
    WHERE 
        RP.PostRank = 1  -- Keep only the most recent post per tag
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Body,
    PD.Tags,
    PD.Author,
    PD.CreationDate,
    PD.LastActivityDate,
    PD.Score,
    PD.ViewCount,
    STRING_AGG(DISTINCT PT.TagName, ', ') AS RelatedTags
FROM 
    PostDetails PD
LEFT JOIN 
    Posts P ON PD.PostId = P.Id
LEFT JOIN 
    STRING_SPLIT(P.Tags, '>') AS PT ON PT.value IN (SELECT TagName FROM PopularTags)
GROUP BY 
    PD.PostId, PD.Title, PD.Body, PD.Tags, PD.Author, PD.CreationDate, PD.LastActivityDate, PD.Score, PD.ViewCount
ORDER BY 
    PD.CreationDate DESC;
