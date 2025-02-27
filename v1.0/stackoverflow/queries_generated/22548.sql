WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.RankByScore,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 3
        AND rp.CommentCount > 0
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        PHT.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    COALESCE(SUM(CASE WHEN phd.HistoryType = 'Post Closed' THEN 1 ELSE 0 END), 0) AS ClosedCount,
    ARRAY_AGG(DISTINCT phd.UserDisplayName) AS Editors,
    COUNT(DISTINCT phd.PostId) AS HistoryCount,
    CASE 
        WHEN COUNT(DISTINCT phd.PostId) > 0 THEN 'Has History'
        ELSE 'No History'
    END AS HistoryStatus,
    TRIM(BOTH ' ' FROM STRING_AGG(DISTINCT phd.Comment, ', ')) AS RecentComments
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryDetails phd ON fp.PostId = phd.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Score
ORDER BY 
    fp.Score DESC, ClosedCount ASC;

WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL OR u.Reputation = 0
)
SELECT DISTINCT 
    ur.ReputationCategory,
    COUNT(DISTINCT p.Id) AS PostsCount
FROM 
    Posts p
JOIN 
    UserReputation ur ON p.OwnerUserId = ur.UserId
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-10-01'
GROUP BY 
    ur.ReputationCategory
ORDER BY 
    COUNT(DISTINCT p.Id) DESC;

SELECT
    p.Id,
    p.Title,
    CASE 
        WHEN p.ViewCount IS NULL THEN 'Views Unknown'
        WHEN p.ViewCount > 100 THEN 'Popular Post'
        ELSE 'Not Popular'
    END AS Popularity,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Posts p
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    p.Score IS NOT NULL OR p.Score IS NULL
GROUP BY 
    p.Id, p.Title, p.ViewCount
HAVING
    COUNT(t.TagName) > 2
ORDER BY 
    p.CreationDate DESC;
