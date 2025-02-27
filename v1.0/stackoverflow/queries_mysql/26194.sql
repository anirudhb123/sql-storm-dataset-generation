
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),

StringProcessing AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.VoteCount,
        GROUP_CONCAT(tag.TagName ORDER BY tag.TagName SEPARATOR ', ') AS AllTags,
        CASE 
            WHEN CHAR_LENGTH(rp.Body) > 1000 THEN 'Long Body'
            ELSE 'Short Body'
        END AS BodyLengthCategory,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 2) THEN 'Popular'
            ELSE 'Less Popular'
        END AS PopularityCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT DISTINCT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '<>', n.n), '<>', -1)) AS TagName
         FROM 
            (SELECT a.N + b.N * 10 + 1 AS n FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
            ) n 
            WHERE n.n <= CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '<>', '')) + 1
        ) AS tag ON TRUE
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.CommentCount, rp.VoteCount
)

SELECT 
    sp.PostId,
    sp.Title,
    sp.OwnerDisplayName,
    sp.CreationDate,
    sp.CommentCount,
    sp.VoteCount,
    sp.AllTags,
    sp.BodyLengthCategory,
    sp.PopularityCategory
FROM 
    StringProcessing sp
WHERE 
    sp.VoteCount > 5  
ORDER BY 
    sp.CreationDate DESC;
