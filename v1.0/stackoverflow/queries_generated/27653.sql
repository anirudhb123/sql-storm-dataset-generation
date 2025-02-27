WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter posts created in the last year
    GROUP BY 
        p.Id
    ORDER BY 
        VoteCount DESC, 
        CommentCount DESC
    LIMIT 10
),
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month'  -- Only consider changes made in the last month
        AND ph.PostId IN (SELECT PostId FROM RankedPosts)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    ra.HistoryDate,
    ra.ChangeType,
    ra.UserDisplayName,
    ra.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC, 
    ra.HistoryDate DESC NULLS LAST;
