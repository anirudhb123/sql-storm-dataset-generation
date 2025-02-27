WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    COALESCE(badges.Name, 'No Badge') AS BadgeName
FROM 
    RecentPosts rp
LEFT JOIN Badges b ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 10;
