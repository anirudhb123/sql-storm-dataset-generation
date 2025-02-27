WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserID, 
        COUNT(b.Id) AS BadgeCount, 
        STRING_AGG(b.Name, ', ' ORDER BY b.Name) AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName, 
    COUNT(DISTINCT rp.PostID) AS TotalPosts,
    COALESCE(SUM(CASE WHEN rp.PostRank = 1 THEN 1 ELSE 0 END), 0) AS BestPosts, 
    ub.BadgeCount,
    ub.BadgeNames,
    AVG(rp.Score) AS AvgScore,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostID
LEFT JOIN 
    Posts p ON p.Id = pl.RelatedPostId
LEFT JOIN 
    Tags t ON t.Id = p.Id
LEFT JOIN 
    UserBadges ub ON ub.UserID = up.Id
WHERE 
    up.Reputation > 100 AND (up.Location IS NOT NULL OR up.WebsiteUrl IS NOT NULL)
GROUP BY 
    up.DisplayName, ub.BadgeCount, ub.BadgeNames
HAVING 
    COUNT(DISTINCT rp.PostID) > 5 AND AVG(rp.Score) > 10
ORDER BY 
    TotalPosts DESC, AvgScore DESC;

-- Note: 
-- This query ranks posts by user and includes various metrics 
-- such as badge count, tags used, and filtering based on conditions,
-- utilizing CTEs for modularity and clarity.
