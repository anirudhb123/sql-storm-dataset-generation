
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1  
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags)-2), '><')) ) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.VALUE
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Body,
    fp.CommentCount,
    fp.VoteCount,
    COALESCE(pt.Tags, 'No Tags') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTags pt ON fp.PostId = pt.PostId
ORDER BY 
    fp.VoteCount DESC, fp.CreationDate DESC;
