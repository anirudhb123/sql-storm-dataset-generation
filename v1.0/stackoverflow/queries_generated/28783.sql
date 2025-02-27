WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(DISTINCT a.Id) AS AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY a.CreationDate DESC) AS LatestAnswerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Only answers
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, 
        p.Title, 
        p.Tags, 
        u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerDisplayName, 
        rp.CommentCount, 
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.LatestAnswerRank = 1 
        AND rp.CommentCount > 5 
        AND rp.AnswerCount >= 3
)
SELECT 
    fp.PostId, 
    fp.Title, 
    fp.OwnerDisplayName, 
    fp.CommentCount, 
    fp.AnswerCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(substring(fp.Tags, 2, length(fp.Tags) - 2), '><')) AS TagName
    ) t ON TRUE
GROUP BY 
    fp.PostId, 
    fp.Title, 
    fp.OwnerDisplayName, 
    fp.CommentCount, 
    fp.AnswerCount
ORDER BY 
    fp.AnswerCount DESC, 
    fp.CommentCount DESC
LIMIT 10;
