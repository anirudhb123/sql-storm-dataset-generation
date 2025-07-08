
WITH TagUsage AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(Tags, '>([^<]+)<', 1, seq)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq
    WHERE 
        PostTypeId = 1  
        AND REGEXP_SUBSTR(Tags, '>([^<]+)<', 1, seq) IS NOT NULL
    GROUP BY 
        TRIM(REGEXP_SUBSTR(Tags, '>([^<]+)<', 1, seq))
),
CommonTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagUsage
    WHERE 
        TagCount > 1  
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation AS OwnerReputation,
        pu.Location,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users pu ON p.OwnerUserId = pu.Id
    WHERE 
        p.PostTypeId = 1  
)
SELECT 
    ct.TagName,
    ct.TagCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.Location
FROM 
    CommonTags ct
JOIN 
    PostDetails pd ON pd.Tags ILIKE '%' || ct.TagName || '%'
ORDER BY 
    ct.Rank, pd.ViewCount DESC;
