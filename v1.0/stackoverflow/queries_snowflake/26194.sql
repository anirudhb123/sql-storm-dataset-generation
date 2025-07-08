
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
        LISTAGG(tag.TagName, ', ') WITHIN GROUP (ORDER BY tag.TagName) AS AllTags,
        CASE 
            WHEN LENGTH(rp.Body) > 1000 THEN 'Long Body'
            ELSE 'Short Body'
        END AS BodyLengthCategory,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 2) THEN 'Popular'
            ELSE 'Less Popular'
        END AS PopularityCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(rp.Tags, '<>')) AS tag ON TRUE
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
