WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')))
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Body, 
        Tags, 
        CommentCount, 
        AnswerCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Body,
    fp.Tags,
    fp.CommentCount,
    fp.AnswerCount,
    fp.VoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.Location AS OwnerLocation
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    fp.VoteCount > 0 -- Select only posts with votes
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;
