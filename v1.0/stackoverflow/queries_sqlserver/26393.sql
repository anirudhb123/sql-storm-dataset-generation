
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        pt.Name AS PostType,
        u.DisplayName AS Author,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
        AND p.Body IS NOT NULL
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.PostType,
    rp.Author,
    rp.CommentCount,
    rp.UpVoteCount,
    STRING_AGG(t.TagName, ',') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         p.Id,
         value AS TagName 
     FROM 
         Posts p
     CROSS APPLY STRING_SPLIT(p.Tags, '>') AS value) t ON rp.PostId = t.Id
WHERE 
    rp.TagRank < 5  
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Score, rp.PostType, rp.Author, rp.CommentCount, rp.UpVoteCount
ORDER BY 
    rp.CreationDate DESC;
