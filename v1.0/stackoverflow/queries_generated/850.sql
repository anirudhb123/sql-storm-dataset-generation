WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score >= 10
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        b.Date,
        RANK() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS badge_rank
    FROM 
        Badges b
    WHERE 
        b.Date > NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.PostId) AS ActiveQuestions,
    b.Class AS BadgeClass,
    COALESCE(MAX(b.Date), 'No recent badges') AS MostRecentBadgeDate,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COALESCE(MAX(rp.ViewCount), 0) AS MaxViewCount
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
LEFT JOIN 
    RecentBadges b ON u.Id = b.UserId AND b.badge_rank = 1
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, b.Class
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    ActiveQuestions DESC, UserName;
