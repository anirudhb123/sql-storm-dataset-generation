WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ClosedDate,
        (SELECT COUNT(*) FROM PostHistory ph2 WHERE ph2.PostId = p.Id AND ph2.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        Posts p
        JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles
    FROM 
        Tags t
        LEFT JOIN Posts p ON t.Id = ANY(STRING_TO_ARRAY(p.Tags, ','))
    GROUP BY 
        t.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ts.TagId,
    ts.PostCount,
    ts.PostTitles,
    CASE 
        WHEN rp.Upvotes > rp.Downvotes THEN 'Positive'
        WHEN rp.Upvotes < rp.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN TagStatistics ts ON ts.PostCount > 0
WHERE 
    rp.rn <= 5
    AND (COALESCE(cp.ClosedDate, TIMESTAMP WITH TIME ZONE 'epoch') >= NOW() - INTERVAL '1 month' OR cp.ClosedDate IS NULL)
ORDER BY 
    rp.CreationDate DESC;
