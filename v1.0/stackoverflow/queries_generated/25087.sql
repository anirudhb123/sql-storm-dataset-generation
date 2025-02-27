WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only Questions
),
TaggedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Tags,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        STRING_AGG(DISTINCT TRIM(UNNEST(string_to_array(RP.Tags, '>'))) , ', ') AS CleanedTags
    FROM 
        RankedPosts RP
    GROUP BY 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score
),
TopFiveTagged AS (
    SELECT 
        T.Tags,
        COUNT(*) AS PostCount,
        AVG(T.Score) AS AverageScore,
        MAX(T.ViewCount) AS MaxViews
    FROM 
        TaggedPosts T
    GROUP BY 
        T.Tags
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    TF.Tags,
    TF.PostCount,
    TF.AverageScore,
    TF.MaxViews,
    JSON_AGG(JSON_BUILD_OBJECT(
        'PostId', P.PostId,
        'Title', P.Title,
        'OwnerDisplayName', P.OwnerDisplayName,
        'CreationDate', P.CreationDate,
        'ViewCount', P.ViewCount,
        'Score', P.Score
    )) AS RelatedPosts
FROM 
    TopFiveTagged TF
JOIN 
    TaggedPosts P ON P.Tags = TF.Tags
GROUP BY 
    TF.Tags, TF.PostCount, TF.AverageScore, TF.MaxViews
ORDER BY 
    TF.PostCount DESC;
