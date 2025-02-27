WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Within the last year
),
TagStatistics AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <'))
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        TagStatistics
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalScore,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score
FROM 
    TopTags tp
JOIN 
    RankedPosts rp ON tp.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '> <'))
WHERE 
    tp.ScoreRank <= 5 -- Top 5 Tags by Score
    AND rp.Rank = 1 -- Highest scoring post per tag
ORDER BY 
    tp.TotalScore DESC, rp.CreationDate DESC;
