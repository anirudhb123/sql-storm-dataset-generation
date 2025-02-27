WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorName,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Filter to only include questions
    GROUP BY 
        p.Id, u.DisplayName
),

RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        p.Title AS PostTitle,
        COALESCE(STRING_AGG(CONVERT(varchar, u.DisplayName), ', '), 'No users') AS UserNames
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' -- Last 30 days activity
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, p.Title, ph.CreationDate
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    ra.HistoryDate,
    ra.UserNames,
    rp.Tags,
    rp.AuthorName,
    rp.TagRank
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.TagRank <= 3 -- Top 3 recent posts per tag
ORDER BY 
    rp.CreationDate DESC, 
    rp.TagRank;
