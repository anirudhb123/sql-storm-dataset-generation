
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.Score
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Owner,
        CreationDate,
        Score,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
    ORDER BY 
        Score DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TagFrequency AS (
    SELECT 
        LTRIM(RTRIM(value)) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    CROSS APPLY 
        STRING_SPLIT(Tags, '>') AS value
    WHERE 
        PostTypeId = 1 AND 
        CreationDate >= '2023-01-01' 
    GROUP BY 
        LTRIM(RTRIM(value))
),
BestTag AS (
    SELECT 
        Tag,
        Frequency
    FROM 
        TagFrequency
    ORDER BY 
        Frequency DESC
    OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.Body,
    tq.Owner,
    tq.CreationDate,
    tq.Score,
    tq.CommentCount,
    bt.Tag AS MostFrequentTag
FROM 
    TopQuestions tq
CROSS JOIN 
    BestTag bt
ORDER BY 
    tq.Score DESC;
