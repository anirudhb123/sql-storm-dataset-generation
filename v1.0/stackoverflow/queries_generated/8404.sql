WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.Rank <= 10
),
PostCommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
EnrichedPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.CreationDate,
        pp.ViewCount,
        pp.OwnerDisplayName,
        pcs.CommentCount,
        pcs.AverageCommentScore
    FROM PopularPosts pp
    JOIN PostCommentStats pcs ON pp.PostId = pcs.PostId
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.Score,
    ep.CreationDate,
    ep.ViewCount,
    ep.OwnerDisplayName,
    ep.CommentCount,
    ep.AverageCommentScore,
    COALESCE(b.Date, 'No badge') AS BadgeDate,
    COALESCE(b.Name, 'No badge') AS BadgeName
FROM EnrichedPosts ep
LEFT JOIN Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ep.PostId)
ORDER BY ep.Score DESC, ep.ViewCount DESC;
