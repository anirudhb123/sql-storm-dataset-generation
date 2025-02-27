WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostDetails AS (
    SELECT 
        t.Tags,
        p.PostId,
        COALESCE(STRING_AGG(DISTINCT CONCAT(b.Name, ' (', b.Class, ')'), ', ') FILTER (WHERE b.Id IS NOT NULL), 'No Badges') AS BadgeDetails
    FROM 
        TopPosts t
    LEFT JOIN 
        Posts p ON t.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        t.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.BadgeDetails,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2) THEN 'Has Upvotes'
        ELSE 'No Upvotes'
    END AS UpvoteStatus,
    COALESCE(SUM(CASE WHEN pht.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosePostCount
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory pht ON pd.PostId = pht.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.Score, pd.OwnerDisplayName, pd.CommentCount, pd.BadgeDetails
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
LIMIT 10;
