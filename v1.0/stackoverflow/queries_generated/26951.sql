WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Posts created in the last year
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalScore,
        AverageViews,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10 -- Only include tags with more than 10 questions
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalScore,
    tp.AverageViews,
    rp.OwnerDisplayName,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViewCount
FROM 
    TopTags tp
JOIN 
    RankedPosts rp ON tp.Tag = ANY(string_to_array(rp.Tags, '>'))
WHERE 
    rp.RankByScore = 1 -- Only top-ranked post for each tag
ORDER BY 
    tp.TagRank;
