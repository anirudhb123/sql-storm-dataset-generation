WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), PopularUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.HighestBadgeClass, 0) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.OwnerUserId,
    pu.DisplayName,
    COUNT(DISTINCT rp.Id) AS PostCount,
    SUM(rp.UpVotes) AS TotalUpVotes,
    SUM(rp.DownVotes) AS TotalDownVotes,
    SUM(rp.CommentCount) AS TotalComments,
    MAX(rp.Score) AS BestPostScore,
    MAX(pu.BadgeCount) AS TotalBadges,
    MAX(pu.HighestBadgeClass) AS HighestBadgeClassRating
FROM 
    RankedPosts rp
JOIN 
    PopularUsers pu ON rp.OwnerUserId = pu.Id
WHERE 
    rp.UserRank <= 5
GROUP BY 
    rp.OwnerUserId, pu.DisplayName
HAVING 
    COUNT(DISTINCT rp.Id) > 10
ORDER BY 
    TotalUpVotes DESC;
