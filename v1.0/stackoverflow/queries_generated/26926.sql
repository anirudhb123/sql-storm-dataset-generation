WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only popular questions
),
TopTagPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Tags,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 3 -- Get top 3 posts for each tag
),
ProcessedTags AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        unnest(string_to_array(Tags, ',')) AS Tag -- Splitting tags for counting
    FROM 
        TopTagPosts
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount,
        AVG(ViewCount) AS AverageViews,
        SUM(Score) AS TotalScore
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AverageViews,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC, TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.Tag,
    tt.PostCount,
    tt.AverageViews,
    tt.TotalScore,
    p.Title,
    p.CreationDate,
    p.OwnerDisplayName
FROM 
    TopTags tt
JOIN 
    TopTagPosts p ON tt.Tag = unnest(string_to_array(p.Tags, ',')) 
WHERE 
    tt.TagRank <= 5 -- Get top 5 tags based on the criteria
ORDER BY 
    tt.TagRank, p.ViewCount DESC;
