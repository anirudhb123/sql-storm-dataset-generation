WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ',') ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1) > 0 AND POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    COUNT(c.Id) AS TotalComments,
    COUNT(DISTINCT v.UserId) AS UniqueVoters,
    MAX(ph.CreationDate) AS LastEdited,
    STRING_AGG(DISTINCT bt.Name, ', ') AS BadgeNames
FROM 
    RankedPosts rp 
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2  -- Only Upvotes
LEFT JOIN 
    Badges bt ON bt.UserId = rp.OwnerDisplayName AND bt.Date >= rp.CreationDate
WHERE 
    rp.TagRank = 1  -- Only the highest ranked posts per tag
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.CommentCount, 
    rp.Tags, rp.OwnerDisplayName, rp.OwnerReputation
ORDER BY 
    SUM(rp.ViewCount) DESC
LIMIT 100;
