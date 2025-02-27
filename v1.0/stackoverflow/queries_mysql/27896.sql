
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.Score > 0 
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)

SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.ViewCount,
    f.Score,
    f.AnswerCount,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS RelatedTags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS EditCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes 
FROM 
    FilteredPosts f
LEFT JOIN 
    Comments c ON f.PostId = c.PostId
LEFT JOIN 
    PostHistory ph ON f.PostId = ph.PostId
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(f.Tags, ',', n.n), ',', -1)) AS tag
     FROM (SELECT a.N + b.N * 10 + 1 AS n
           FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
           ) n
     ) tag_array ON TRUE
LEFT JOIN 
    Tags t ON tag_array.tag = t.TagName
LEFT JOIN 
    Votes v ON f.PostId = v.PostId
GROUP BY 
    f.PostId, f.Title, f.OwnerDisplayName, f.ViewCount, f.Score, f.AnswerCount
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
