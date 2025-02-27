WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentTotal,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01' 
        AND p.ViewCount IS NOT NULL
        AND (p.ViewCount + COALESCE(p.AnswerCount, 0)) > 10
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId AS EditorUserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND ph.PostHistoryTypeId IN (4, 5, 6, 10)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.CommentTotal,
    rp.UpvoteCount,
    rp.DownvoteCount,
    COALESCE(rph.EditorUserId, -1) AS LastEditedBy, -- -1 if null (might correspond to deleted users)
    CASE 
        WHEN rph.HistRank = 1 THEN 'Recently Edited' 
        ELSE 'Not Recently Edited' 
    END AS EditStatus,
    CASE 
        WHEN rp.CommentTotal > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    RankedPosts rp
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
LEFT JOIN 
    Posts related ON related.Id = pl.RelatedPostId
LEFT JOIN 
    Tags t ON t.Id = related.Id
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId = rp.PostId
WHERE 
    rp.rn = 1 -- getting the most recent post for each user
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, 
    rp.CommentTotal, rp.UpvoteCount, rp.DownvoteCount,
    rph.EditorUserId, rph.HistRank
HAVING 
    (rp.UpvoteCount - rp.DownvoteCount) > 5
ORDER BY 
    rp.Score DESC, rp.PostCreationDate ASC;
