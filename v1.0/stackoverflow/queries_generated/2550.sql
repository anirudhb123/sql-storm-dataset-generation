WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 10 AND 
        SUM(p.Score) > 100
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS TopPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
ORDER BY 
    tu.TotalScore DESC
LIMIT 10;

WITH RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    p.Id,
    p.Title,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount
FROM 
    Posts p
LEFT JOIN 
    RecentComments rc ON p.Id = rc.PostId
WHERE 
    p.ViewCount > 1000
ORDER BY 
    p.CreationDate DESC
LIMIT 5;

SELECT 
    p.Id AS PostId,
    pc.CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    p.CreationDate, 
    UPPER(p.Title) AS UpperTitle
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) pc ON p.Id = pc.PostId
WHERE 
    p.LastActivityDate IS NOT NULL
GROUP BY 
    p.Id, pc.CommentCount
HAVING 
    COUNT(v.Id) > 0 OR pc.CommentCount IS NOT NULL
ORDER BY 
    p.CreationDate DESC;
