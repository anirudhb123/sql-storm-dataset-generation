WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    ISNULL(ph.ClosedDate, 'Not Closed') AS ClosedStatus,
    ISNULL(ph.ReopenedDate, 'Not Reopened') AS ReopenedStatus,
    up.BadgeCount,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    UserActivity up
JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    up.UpVotes > 10
ORDER BY 
    up.BadgeCount DESC, rp.Score DESC
FETCH FIRST 10 ROWS ONLY;

-- Also testing various string and NULL-logics
SELECT 
    String_Expression_Array AS ConcatenatedTags,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    LATERAL unnest(string_to_array(p.Titles, ' ')) AS String_Expression_Array ON true
LEFT JOIN 
    Tags t ON t.TagName = String_Expression_Array 
WHERE 
    t.TagName IS NULL OR t.TagName LIKE '%SQL%'
GROUP BY 
    p.Id;

This query incorporates various SQL constructs and logic, including CTEs for organization of complex data, ranking functions, and conditionals based on vote counts, as well as string aggregation with NULL checks and conditions.
