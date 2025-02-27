WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with a non-zero score
), TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(TRANSLATE(Tags, '<>', ''), '><')) AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        TagName
), TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.TagName,
    tt.QuestionCount,
    tt.TotalScore,
    CASE
        WHEN tt.TagCount > 50 THEN 'Active'
        WHEN tt.TagCount > 10 THEN 'Moderate'
        ELSE 'Inactive'
    END AS TagActivityStatus
FROM 
    TopTags tt
WHERE 
    TagRank <= 10 -- Get top 10 tags based on total score
ORDER BY 
    tt.TotalScore DESC;

-- Display related post link count
SELECT 
    p.Id AS PostId,
    COUNT(pl.RelatedPostId) AS RelatedPostCount
FROM 
    Posts p
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id
ORDER BY 
    RelatedPostCount DESC
LIMIT 10;

-- Bonus: Get recent comments on the top 5 highest scored posts
WITH TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
)
SELECT 
    tp.Title,
    c.Text AS CommentText,
    c.CreationDate AS CommentDate,
    c.UserDisplayName
FROM 
    Comments c
JOIN 
    TopPosts tp ON c.PostId = tp.Id
WHERE 
    tp.PostRank <= 5 -- Get comments on the top 5 posts
ORDER BY 
    tp.Score DESC, c.CreationDate DESC;
