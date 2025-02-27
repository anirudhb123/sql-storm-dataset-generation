WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))::int)
                             WHERE t.TagName IS NOT NULL)
    WHERE 
        p.PostTypeId = 1 -- only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- within the last year
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        c.Name AS CloseReason
    FROM 
        PostHistory ph 
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    CASE 
        WHEN cp.CloseDate IS NOT NULL THEN cp.CloseDate 
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN cp.CloseReason IS NOT NULL THEN cp.CloseReason 
        ELSE 'N/A' 
    END AS CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5; -- top 5 questions for each user
