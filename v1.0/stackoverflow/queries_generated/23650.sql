WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) as CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= now() - interval '1 year'
),
FromLastYear AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.RankScore,
        rp.CommentCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badges') AS BadgeName,
        pht.Name as PostHistoryType,
        COUNT(ph.Id) FILTER (WHERE ph.CreationDate >= now() - interval '1 month') AS RecentEdits
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId 
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
    WHERE 
        rp.RankScore <= 5 -- Focus on top 5 posts
    GROUP BY 
        rp.PostId, rp.Title, rp.RankScore, u.DisplayName, b.Name, pht.Name
),
Summary AS (
    SELECT 
        MAX(PostId) AS PostId,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueOwners,
        COUNT(PostId) FILTER (WHERE CommentCount > 0) AS ActivePosts,
        STRING_AGG(DISTINCT BadgeName, ', ') AS BadgeList,
        COUNT(*) AS TotalPosts
    FROM 
        FromLastYear
)

SELECT 
    fl.PostId,
    fl.Title,
    fl.OwnerDisplayName,
    fl.CommentCount,
    fl.RecentEdits,
    s.UniqueOwners,
    s.ActivePosts,
    s.BadgeList,
    s.TotalPosts
FROM 
    FromLastYear fl
CROSS JOIN 
    Summary s
WHERE 
    fl.CommentCount IS NOT NULL
ORDER BY 
    fl.RecentEdits DESC, fl.CommentCount DESC
LIMIT 25;

This SQL query includes multiple constructs such as Common Table Expressions (CTEs), window functions, correlated subqueries, and conditional aggregation. It ranks posts, counts comments, associates users with their badges, and retrieves posts edited recently, all while showcasing an intricate relationship between users, posts, and edits.
