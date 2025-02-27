WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ph.LastEditDate,
        ph.Comment AS LastEditComment
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
        AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        p.Id, u.DisplayName, ph.LastEditDate, ph.Comment
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.VoteTypeId IN (1, 4) -- Accepted votes and Favorited bookmarks
    GROUP BY 
        u.Id
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.LastEditDate,
    pd.LastEditComment,
    ur.UserId,
    ur.DisplayName AS UserDisplayName,
    ur.TotalBadgeClass,
    ur.PostsCreated,
    ur.TotalBounty
FROM 
    PostDetails pd
JOIN 
    UserReputation ur ON pd.OwnerDisplayName = ur.DisplayName
WHERE 
    pd.ViewCount > 100 AND 
    pd.AnswerCount > 5
ORDER BY 
    pd.ViewCount DESC, 
    pd.AnswerCount DESC;
