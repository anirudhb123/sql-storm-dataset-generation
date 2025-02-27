WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
           AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
           AND v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)

, UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

, PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        STRING_AGG(ph.Comment, '; ') FILTER (WHERE ph.Comment IS NOT NULL) AS Comments
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserDisplayName
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    ub.TotalBadges,
    ub.BadgeNames,
    phd.Comments,
    (CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        ELSE (CASE 
            WHEN rp.Score > 0 THEN 'Positive Score'
            WHEN rp.Score < 0 THEN 'Negative Score'
            ELSE 'Neutral Score'
        END)
    END) AS ScoreCategory,
    (CASE 
        WHEN phd.HistoryDate IS NULL THEN 'No Recent Changes'
        ELSE FORMAT(phd.HistoryDate, 'dd-MM-yyyy HH:mm:ss')
    END) AS LastChangeDate,
    (SELECT 
        COUNT(DISTINCT pl.RelatedPostId) 
     FROM PostLinks pl 
     WHERE pl.PostId = rp.PostId) AS RelatedPostsCount,
    COALESCE((SELECT STRING_AGG(t.TagName, ', ') 
              FROM Tags t 
              WHERE t.WikiPostId = rp.PostId), 'No Tags') AS PostTags
FROM RankedPosts rp
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN PostHistoryData phd ON rp.PostId = phd.PostId
WHERE rp.Rank = 1 
ORDER BY rp.Score DESC NULLS LAST, rp.CreationDate DESC
LIMIT 100;

-- Additional runtime considerations
-- This query combines several advanced SQL constructs while considering edge cases
-- like NULL values, aggregates, window functions, and correlated subqueries.
