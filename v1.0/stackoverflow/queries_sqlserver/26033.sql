
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    OUTER APPLY 
        (SELECT value AS tag 
         FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') 
         WHERE value IS NOT NULL) AS tag
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerDisplayName, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.VoteCount DESC, rp.CommentCount DESC) AS rn
    FROM 
        RankedPosts rp
    WHERE 
        rp.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AcceptedAnswerId,
    fp.CommentCount,
    fp.VoteCount,
    fp.Tags
FROM 
    FilteredPosts fp
WHERE 
    fp.rn <= 10;
