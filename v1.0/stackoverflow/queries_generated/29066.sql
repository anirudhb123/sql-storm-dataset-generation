WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
MostPopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag(t)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
EnhancedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.CreationDate DESC) AS OverallRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
),
FinalBenchmark AS (
    SELECT 
        ep.PostId,
        ep.Title,
        ep.Body,
        ep.Tags,
        ep.CreationDate,
        ep.Score,
        ep.OwnerDisplayName,
        ep.OwnerReputation,
        ep.CommentCount,
        mt.TagName AS MostPopularTag
    FROM 
        EnhancedPosts ep
    JOIN 
        MostPopularTags mt ON ep.Tags LIKE '%' || mt.TagName || '%'
    WHERE 
        ep.OverallRank <= 100 -- Limiting to top 100 posts for efficiency
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    CreationDate,
    Score,
    OwnerDisplayName,
    OwnerReputation,
    CommentCount,
    MostPopularTag
FROM 
    FinalBenchmark
ORDER BY 
    Score DESC, CreationDate DESC;
