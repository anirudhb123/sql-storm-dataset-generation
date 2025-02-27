WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        U.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.Body, U.DisplayName, p.CreationDate
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- Selecting the latest version of each post
)

SELECT 
    fp.Title,
    SUBSTRING(fp.Body, 1, 200) AS ShortBody,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.AnswerCount,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
               FROM UNNEST(STRING_TO_ARRAY(fp.Tags, ',')) AS tag 
               JOIN Tags t ON tag = t.TagName), 'No Tags') AS Tags
FROM 
    FilteredPosts fp
JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Include only post close/reopen history
ORDER BY 
    fp.CreationDate DESC
LIMIT 50;

