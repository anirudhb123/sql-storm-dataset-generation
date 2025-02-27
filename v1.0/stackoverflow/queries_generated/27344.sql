WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON tag_array.value = t.TagName
    LEFT JOIN 
        Tags t ON t.TagName = tag_array.value
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND 
        rp.AnswerCount > 0 AND 
        rp.VoteCount > 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Author,
    fp.CreationDate,
    fp.CommentCount,
    fp.AnswerCount,
    fp.VoteCount,
    fp.Tags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC;
