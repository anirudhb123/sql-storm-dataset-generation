WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_array)
    WHERE 
        p.PostTypeId = 1  -- Filtering for questions
    GROUP BY 
        p.Id, u.DisplayName
),
HighEngagementPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        CommentCount,
        AnswerCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10  -- Selecting top 10 recent questions
    ORDER BY 
        ViewCount DESC
)
SELECT 
    h.PostId,
    h.Title,
    h.OwnerDisplayName,
    h.CreationDate,
    h.ViewCount,
    h.CommentCount,
    h.AnswerCount,
    h.Tags,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    HighEngagementPosts h
LEFT JOIN 
    PostHistory ph ON h.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edit history
ORDER BY 
    h.ViewCount DESC, h.CreationDate DESC;
