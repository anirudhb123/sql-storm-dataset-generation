
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags)-2), '>')) AS tag ON tag.VALUE IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.VALUE
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
        rp.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '1 YEAR'
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
