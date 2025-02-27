WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
StringProcessed AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags,
        SPLIT_PART(rp.Title, ' ', 1) AS FirstWord, 
        LENGTH(rp.Body) AS BodyLength,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3 -- Taking the latest 3 posts per tag
)
SELECT 
    sp.OwnerDisplayName,
    COUNT(DISTINCT sp.PostId) AS TotalPosts,
    SUM(sp.BodyLength) AS TotalBodyLength,
    AVG(sp.Score) AS AverageScore,
    StringAgg(DISTINCT sp.FirstWord, ', ') AS UniqueFirstWords
FROM 
    StringProcessed sp
GROUP BY 
    sp.OwnerDisplayName
HAVING 
    COUNT(DISTINCT sp.PostId) > 5 -- Only include users with more than 5 posts
ORDER BY 
    TotalBodyLength DESC;
