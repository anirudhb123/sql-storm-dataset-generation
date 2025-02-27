WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ph.UserDisplayName AS LastEditedBy,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    WHERE 
        p.CreationDate >= '2023-01-01'
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.Upvotes,
    ue.Downvotes,
    ue.CommentCount,
    ue.PostCount,
    ue.BadgeCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate AS PostCreationDate,
    pd.ViewCount,
    pd.Score,
    COALESCE(pd.LastEditedBy, 'N/A') AS LastEditedBy,
    COALESCE(pd.LastEditDate, 'N/A') AS LastEditDate,
    ARRAY_LENGTH(string_to_array(pd.Tags, ','), 1) AS TagCount
FROM 
    UserEngagement ue
LEFT JOIN 
    PostDetails pd ON ue.UserId = pd.OwnerUserId
ORDER BY 
    ue.Upvotes DESC, ue.Downvotes ASC, ue.CommentCount DESC;
