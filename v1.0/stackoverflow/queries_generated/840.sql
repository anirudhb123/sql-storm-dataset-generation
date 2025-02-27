WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only considering Questions
),
PostWithBadges AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.Class, 0) AS BadgeClass,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM RankedPosts r
    LEFT JOIN Users u ON r.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE r.Rank <= 3 -- Top 3 questions per user
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
FilteredPosts AS (
    SELECT 
        p.*,
        c.LastClosedDate
    FROM PostWithBadges p
    LEFT JOIN ClosedPosts c ON p.PostId = c.PostId
    WHERE c.LastClosedDate IS NULL OR c.LastClosedDate < NOW() - INTERVAL '1 year' -- Including only non-closed or older posts
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.BadgeClass,
    fp.BadgeName,
    COALESCE(SUM(com.Score), 0) AS TotalCommentScore,
    COUNT(DISTINCT v.UserId) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM FilteredPosts fp
LEFT JOIN Comments com ON com.PostId = fp.PostId
LEFT JOIN Votes v ON v.PostId = fp.PostId
LEFT JOIN LATERAL (
    SELECT UNNEST(string_to_array(fp.Tags, '<>')) AS TagName
) t ON TRUE
GROUP BY 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.BadgeClass,
    fp.BadgeName
ORDER BY fp.Score DESC, fp.CreationDate ASC
LIMIT 10;
