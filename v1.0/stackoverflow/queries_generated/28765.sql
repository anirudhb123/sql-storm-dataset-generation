WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tagName ON tagName IS NOT NULL
    LEFT JOIN 
        Tags t ON tagName LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.RevisionGUID,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.Tags,
        cp.ClosedDate,
        cp.ClosedBy,
        cp.CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.Tags,
    fp.ClosedDate,
    fp.ClosedBy,
    fp.CloseReason
FROM 
    FinalPosts fp
WHERE 
    fp.ClosedDate IS NOT NULL
ORDER BY 
    fp.ClosedDate DESC
LIMIT 10;

-- This query retrieves the most recently closed questions, including their details, number of answers, 
-- and tags associated with them, serving as a benchmark for string processing capabilities. 
