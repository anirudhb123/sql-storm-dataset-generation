WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        Score,
        OwnerDisplayName,
        PostRank,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
OldPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.CreationDate < NOW() - INTERVAL '1 year'
)
SELECT 
    tp.Title AS RecentTopPostTitle,
    tp.ViewCount AS RecentTopPostViews,
    tp.Score AS RecentTopPostScore,
    tp.OwnerDisplayName AS RecentTopPostOwner,
    op.Title AS OldPostTitle,
    op.CreationDate AS OldPostCreationDate,
    op.Score AS OldPostScore
FROM 
    TopPosts tp
FULL OUTER JOIN 
    OldPosts op ON tp.OwnerUserId = op.OwnerUserId
ORDER BY 
    tp.Score DESC NULLS LAST, 
    op.CreationDate ASC;
