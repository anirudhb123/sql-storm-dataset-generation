
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(rev.Id) AS RevisionCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory rev ON p.Id = rev.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) tag_name
        FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
              SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE numbers.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag_names ON tag_names.tag_name IS NOT NULL
    LEFT JOIN 
        Tags t ON tag_names.tag_name = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
