WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::jsonb->>'reason'::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, ',')::int[])
    WHERE 
        pt.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(c.CloseDate, 'No Close'::timestamp) AS CloseDate,
    COALESCE(c.ClosedBy, 'N/A') AS ClosedBy,
    COALESCE(c.CloseReason, 'Not Applicable') AS CloseReason,
    ARRAY_AGG(pt.TagName) AS PopularTags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostHistory c ON rp.PostId = c.PostId
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 10
WHERE 
    rp.Rank <= 5 -- Top 5 posts by type
GROUP BY 
    rp.PostId, 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    c.CloseDate,
    c.ClosedBy,
    c.CloseReason
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
