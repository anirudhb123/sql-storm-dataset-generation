WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.ViewCount > 0
),

FrequentTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS TagName, 
        COUNT(*) AS Frequency
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10  -- Threshold for popular tags
),

PostWithPopularTags AS (
    SELECT 
        rp.*,
        ft.Frequency
    FROM 
        RankedPosts rp
    JOIN 
        FrequentTags ft ON rp.Tags LIKE '%' || ft.TagName || '%'
),

HighestScoringPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.Score >= 0
)

SELECT 
    p.PostId, 
    p.Title AS QuestionTitle, 
    p.Body AS QuestionBody, 
    p.ViewCount, 
    p.AnswerCount, 
    ft.TagName AS PopularTag, 
    hsp.Title AS HighScorePostTitle,
    hsp.Score AS HighScore
FROM 
    PostWithPopularTags p
JOIN 
    HighestScoringPosts hsp ON p.PostId <> hsp.Id
WHERE 
    p.TagRank = 1  -- Top ranked posts per tag
ORDER BY 
    p.ViewCount DESC, 
    hsp.Score DESC
LIMIT 100;
