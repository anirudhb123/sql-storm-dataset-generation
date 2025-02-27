WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RankByDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),

PostScoreAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        pt.Name AS PostTypeName,
        t.TagName,
        CASE 
            WHEN rp.RankByScore = 1 THEN 'High Score'
            WHEN rp.RankByDate = 1 THEN 'Recent Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = rp.PostTypeId
    JOIN 
        UNNEST(string_to_array(rp.Body, ' ')) AS word ON LOWER(word) NOT IN ('the', 'is', 'and', 'or', 'to', 'of', 'in')  -- Filter out common words
    JOIN 
        PopularTags t ON t.TagName ILIKE '%' || word || '%'
)

SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.PostCategory,
    STRING_AGG(DISTINCT p.TagName, ', ') AS AssociatedTags
FROM 
    PostScoreAnalysis p
GROUP BY 
    p.PostId, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.PostCategory
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
