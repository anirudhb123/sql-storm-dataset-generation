WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AverageVote,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Focus on Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, u.DisplayName
), 
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        CommentCount,
        AverageVote,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Get top 10 recent Questions and Answers
)

SELECT 
    fp.PostId,
    fp.Title,
    SUBSTRING(fp.Body, 1, 300) || '...' AS ShortBody, -- Create a short version of the body for display
    fp.CreationDate,
    fp.LastActivityDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.AverageVote,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags -- Aggregate tags for a post
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON tag_array IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag_array
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.LastActivityDate, fp.OwnerDisplayName, fp.CommentCount, fp.AverageVote
ORDER BY 
    fp.LastActivityDate DESC;
