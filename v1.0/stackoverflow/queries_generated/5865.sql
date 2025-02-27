WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.CommentCount, 
        p.AnswerCount, 
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.BadgeCount, 0) AS OwnerBadgeCount,
        ARRAY_AGG(t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName(t) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, b.BadgeCount
),
VoteInfo AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes, 
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pm.PostId, 
    pm.Title, 
    pm.CreationDate, 
    pm.Score, 
    pm.ViewCount, 
    pm.CommentCount, 
    pm.AnswerCount, 
    pm.OwnerDisplayName, 
    pm.OwnerBadgeCount, 
    vi.Upvotes, 
    vi.Downvotes, 
    phs.CloseCount, 
    phs.ReopenCount, 
    pm.TagsArray 
FROM 
    PostMetrics pm
LEFT JOIN 
    VoteInfo vi ON pm.PostId = vi.PostId
LEFT JOIN 
    PostHistorySummary phs ON pm.PostId = phs.PostId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;
