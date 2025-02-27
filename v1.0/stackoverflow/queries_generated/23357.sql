WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        (SELECT 
            COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT 
            STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT 
                            unnest(string_to_array(p.Tags, '><')::int[]) 
                        )) AS TagList
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes only
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
LatestPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.PostHistoryTypeId) AS LastAction,
        STRING_AGG(ph.Comment, '; ') AS UserComments,
        ph.UserDisplayName
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY ph.PostId, ph.UserDisplayName
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        COALESCE(lp.UserComments, 'No comments') AS LastUserComments,
        CASE 
            WHEN lp.LastAction = 10 THEN 'Closed'
            WHEN lp.LastAction = 11 THEN 'Reopened'
            ELSE 'Active'
        END AS Status,
        rp.TagList
    FROM RankedPosts rp
    LEFT OUTER JOIN LatestPostHistory lp ON rp.PostId = lp.PostId
    WHERE rp.rn = 1 -- Get the first post per owner
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.LastUserComments,
    ps.Status,
    COALESCE(ps.TagList, 'No Tags') AS Tags
FROM PostStatistics ps
WHERE ps.Status != 'Closed' 
  AND ps.ViewCount >= (SELECT AVG(ViewCount) FROM Posts)
ORDER BY ps.ViewCount DESC, ps.Score DESC
LIMIT 50;
