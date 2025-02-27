WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(rev.Id) AS RevisionCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory rev ON p.Id = rev.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag -- Splitting tags
    AS tag_name ON tag_name IS NOT NULL
    LEFT JOIN 
        Tags t ON tag_name = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName
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
    rp.RevisionRank <= 10  -- Top 10 posts by revisions
ORDER BY 
    rp.RevisionCount DESC, 
    rp.CreationDate ASC;
