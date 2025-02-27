WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only considering Questions
        p.CreationDate > NOW() - INTERVAL '1 year' -- Questions from the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1 -- Selecting the highest scoring post per tag
),
PostStatistics AS (
    SELECT 
        t.Tags,
        COUNT(DISTINCT t.PostId) AS TotalPosts,
        AVG(t.Score) AS AverageScore,
        MAX(t.Score) AS MaxScore,
        MIN(t.Score) AS MinScore
    FROM 
        TopPosts t
    GROUP BY 
        t.Tags
),
FrequentTags AS (
    SELECT 
        Tags,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tags
    HAVING 
        COUNT(*) > 50 -- Consider tags with more than 50 questions
)
SELECT 
    pt.Tags,
    ps.TotalPosts,
    ps.AverageScore,
    ps.MaxScore,
    ps.MinScore,
    ft.TagCount
FROM 
    PostStatistics ps
JOIN 
    FrequentTags ft ON ps.Tags = ft.Tags
ORDER BY 
    ps.AverageScore DESC, -- Highest average score first
    ft.TagCount DESC; -- Then by the count of posts for the tag
