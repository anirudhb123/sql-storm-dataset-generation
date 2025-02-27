
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
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        p.PostTypeId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    CROSS APPLY (
        SELECT value AS word
        FROM STRING_SPLIT(rp.Body, ' ')
    ) AS word
    JOIN 
        PopularTags t ON t.TagName LIKE '%' + word.word + '%'
    WHERE 
        LOWER(word.word) NOT IN ('the', 'is', 'and', 'or', 'to', 'of', 'in')  
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
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
