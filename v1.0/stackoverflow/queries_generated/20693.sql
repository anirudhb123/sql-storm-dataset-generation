WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_arr ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_arr
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
)

SELECT 
    up.OwnerUserId AS UserId,
    u.DisplayName AS UserDisplayName,
    SUM(CASE WHEN r.UpVoteCount > r.DownVoteCount THEN 1 ELSE 0 END) AS PositiveImpactCount,
    COUNT(DISTINCT r.PostId) AS TotalPostsCount,
    STRING_AGG(DISTINCT r.Title, ', ') AS RecentPostTitles,
    COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Users up ON up.Id = r.OwnerUserId
WHERE 
    r.Score > 0
    AND u.Reputation IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM Posts p2 
        WHERE p2.OwnerUserId = u.Id 
              AND p2.CreationDate < r.CreationDate
              AND p2.AcceptedAnswerId IS NOT NULL
    )
GROUP BY 
    up.OwnerUserId, u.DisplayName
HAVING 
    COUNT(DISTINCT r.PostId) > 5
ORDER BY 
    PositiveImpactCount DESC, TotalPostsCount DESC
LIMIT 10;

-- This query selects users who own positively rated posts while considering the impact of their scores, 
-- incorporating an interesting mix of CTEs, window functions, 
-- and correlated subqueries to filter results optimally.
