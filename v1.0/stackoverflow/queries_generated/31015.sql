WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
    HAVING 
        COUNT(c.Id) > 5
),

TopTags AS (
    SELECT 
        t.TagName, 
        t.Count,
        ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) AS EditCount,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- considering edits to title, body, and tags
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    COALESCE(pts.EditCount, 0) AS TotalEdits,
    pts.EditComments,
    tt.TagName
FROM 
    RecentPosts rp
LEFT JOIN 
    PostHistoryStats pts ON rp.PostId = pts.PostId
LEFT JOIN 
    TopTags tt ON tt.TagRank <= 3 -- Limit to top 3 tags
WHERE 
    rp.rn <= 10 -- limit to top 10 most recent posts
ORDER BY 
    rp.CreationDate DESC;
