WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
        AND p.Score > 0   -- Only consider questions with scores
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        crt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id  -- Cast the comment to int to match CloseReasonTypes
    WHERE 
        ph.PostHistoryTypeId = 10  -- Only Closed posts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostCreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    COALESCE(cp.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    (SELECT 
         unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName, 
         PostId 
     FROM 
         Posts 
     WHERE 
         PostTypeId = 1) t ON rp.PostId = t.PostId
WHERE 
    rp.Rank <= 5  -- Top 5 ranked questions per tag
GROUP BY 
    rp.PostId, rp.Title, rp.PostCreationDate, rp.Score, rp.ViewCount, 
    rp.AnswerCount, rp.CommentCount, rp.OwnerDisplayName, rp.OwnerReputation, 
    cp.CloseDate, cp.CloseReason
ORDER BY 
    rp.Score DESC, rp.PostCreationDate ASC;
