WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with positive scores
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substr(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgViewCount,
        AvgScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 5 -- Only tags with more than 5 questions
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    tt.Tag AS PopularTag,
    tt.PostCount AS TagPostCount,
    tt.AvgViewCount AS TagAvgViewCount,
    tt.AvgScore AS TagAvgScore
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE '%' || tt.Tag || '%'
WHERE 
    rp.Rank <= 10 -- Get top 10 ranked questions from each reputation tier
ORDER BY 
    rp.OwnerDisplayName, tt.TagRank, rp.Score DESC;
