
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
TagStatistics AS (
    SELECT 
        t.Value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS t
    WHERE 
        PostTypeId = 1
    GROUP BY 
        t.Value
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 5
    LIMIT 10
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.AnswerCount,
    RP.CommentCount,
    RP.OwnerDisplayName,
    PT.TagName,
    PT.PostCount AS PopularTagCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PopularTags PT ON PT.TagName IN (SELECT Value FROM LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(RP.Tags, 2, LENGTH(RP.Tags) - 2), '><')))
WHERE 
    RP.ScoreRank <= 3 
ORDER BY 
    RP.CreationDate DESC;
