WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(rp.Tags, '><'))
WHERE 
    rp.Rank <= 5 -- Top 5 recent questions per tag
    AND tt.TagRank <= 10 -- Count of top 10 tags
ORDER BY 
    tt.TagCount DESC, rp.CreationDate DESC;
This query ranks posts of type "Questions" that have been created over the last year, pulling the top 5 recent questions for each of the top 10 most-used tags to benchmark the system's string processing capabilities around tags and posts while considering multiple joins and aggregations.
