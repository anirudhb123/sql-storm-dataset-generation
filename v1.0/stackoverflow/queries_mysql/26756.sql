
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > NOW() - INTERVAL 1 YEAR
),
TaggedQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        OwnerReputation,
        CreationDate,
        LastActivityDate,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1  
        AND Tags IS NOT NULL 
),
MostCommonTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TaggedQuestions
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10 
)
SELECT 
    tq.OwnerDisplayName,
    tq.Title,
    tq.Body,
    tq.Tags,
    tq.ViewCount,
    tq.Score,
    ct.TagName,
    ct.TagCount
FROM 
    TaggedQuestions tq
JOIN 
    MostCommonTags ct ON FIND_IN_SET(ct.TagName, tq.Tags) > 0  
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
