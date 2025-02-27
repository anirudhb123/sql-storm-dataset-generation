
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, -1) AS HasAcceptedAnswer,  
        p.Tags,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN p.PostTypeId = 1 THEN 'Question' 
                ELSE 'Other'
            END 
            ORDER BY 
                p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')  
        AND p.Score > 0  
),
UniqueTags AS (
    SELECT 
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        Tags IS NOT NULL
),
TagFrequency AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        UniqueTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10  
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.HasAcceptedAnswer,
        rp.ViewCount,
        rp.Score,
        STRING_AGG(DISTINCT tf.Tag, ',') AS PopularTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagFrequency tf ON tf.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.HasAcceptedAnswer, rp.ViewCount, rp.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    CASE WHEN ps.HasAcceptedAnswer = -1 THEN 'No Accepted Answer' ELSE 'Has Accepted Answer' END AS AcceptedAnswer,
    ps.ViewCount,
    ps.Score,
    (SELECT COUNT(*) FROM STRING_SPLIT(ps.PopularTags, ',')) AS TagCount,
    ps.PopularTags
FROM 
    PostStatistics ps
WHERE 
    (SELECT COUNT(*) FROM STRING_SPLIT(ps.PopularTags, ',')) > 0  
ORDER BY 
    ps.ViewCount DESC,  
    ps.Score DESC;
