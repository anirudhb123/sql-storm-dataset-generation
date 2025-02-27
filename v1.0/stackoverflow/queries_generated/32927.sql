WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByCreation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
TagsInfo AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY (string_to_array(p.Tags, ',')::int[]) -- Assuming Tags are stored as a comma-separated string of IDs
    GROUP BY 
        t.TagName
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.Upvotes,
    rp.Downvotes,
    cp.ClosedDate,
    cp.CloseReason,
    ti.TagPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    TagsInfo ti ON ti.TagPostCount = rp.AnswerCount
WHERE 
    rp.RankByCreation = 1 -- Only the most recent questions
    AND (cp.ClosedDate IS NULL OR cp.ClosedDate > rp.CreationDate) -- Only questions that are not closed or are closed after creation
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
