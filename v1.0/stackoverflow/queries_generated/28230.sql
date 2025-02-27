WITH RankedPosts AS (
    -- Rank posts based on the number of comments, then by score
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CommentCount DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Select only questions
),

RecentEdits AS (
    -- Get the most recent edit history of the top-ranked posts
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Comment AS EditComment,
        ph.Text AS NewText,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Body
),

UserBadgeCounts AS (
    -- Count badges for each user
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

-- Final selection to benchmark string processing
SELECT 
    rp.Title,
    rp.Score,
    rp.CommentCount,
    re.EditDate,
    re.Editor,
    re.NewText,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1 -- Get the latest edit only
JOIN 
    Users u ON rp.PostId = u.Id
JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 10; -- Only get top 10 posts
