
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(rev.Id) AS RevisionCount,
        LISTAGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory rev ON p.Id = rev.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag_name ON tag_name.VALUE IS NOT NULL
    LEFT JOIN 
        Tags t ON tag_name.VALUE = t.TagName
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),

RankedPosts AS (
    SELECT 
        fp.*,
        RANK() OVER (ORDER BY fp.RevisionCount DESC, fp.CreationDate ASC) AS RevisionRank
    FROM 
        FilteredPosts fp
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.TagList,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.RevisionCount,
    rp.RevisionRank
FROM 
    RankedPosts rp
WHERE 
    rp.RevisionRank <= 10  
ORDER BY 
    rp.RevisionCount DESC, 
    rp.CreationDate ASC;
