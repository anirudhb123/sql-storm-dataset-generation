WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(substring(Tags, 2, length(Tags)-2), '><'), 1) AS TagCount 
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.PostTypeId = 1  -- Only questions
),
PostStatistics AS (
    SELECT 
        PostId, 
        COUNT(c.Id) AS CommentCount, 
        SUM(v.VoteTypeId = 2) AS Upvotes, 
        SUM(v.VoteTypeId = 3) AS Downvotes 
    FROM 
        RecentPosts rp 
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId 
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId 
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEditDate, 
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastTitleEdit,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        PostHistory ph 
    JOIN 
        RecentPosts rp ON ph.PostId = rp.PostId 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    phs.LastEditDate,
    phs.LastTitleEdit,
    phs.UniqueEditors,
    rp.TagCount
FROM 
    RecentPosts rp
JOIN 
    PostStatistics ps ON rp.PostId = ps.PostId
JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
ORDER BY 
    ps.Upvotes DESC, 
    ps.CommentCount DESC;
