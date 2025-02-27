
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
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
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
        (SELECT DISTINCT LOWER(word) AS word 
         FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Body, ' ', numbers.n), ' ', -1) AS word
               FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                     UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
               WHERE CHAR_LENGTH(rp.Body) -CHAR_LENGTH(REPLACE(rp.Body, ' ', '')) >= numbers.n - 1) wordList
         ) AS word ON word.word NOT IN ('the', 'is', 'and', 'or', 'to', 'of', 'in')  
    JOIN 
        PopularTags t ON t.TagName LIKE CONCAT('%', word.word, '%')
)

SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.PostCategory,
    GROUP_CONCAT(DISTINCT p.TagName ORDER BY p.TagName ASC SEPARATOR ', ') AS AssociatedTags
FROM 
    PostScoreAnalysis p
GROUP BY 
    p.PostId, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.PostCategory
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
