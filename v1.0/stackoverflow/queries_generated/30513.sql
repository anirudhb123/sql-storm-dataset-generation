WITH RECURSIVE UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (PARTITION BY b.UserId ORDER BY COUNT(b.Id) DESC) AS BadgeRank
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(rp.PostCount, 0) AS TotalRecentPosts
    FROM 
        Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            Posts
        WHERE 
            CreationDate >= NOW() - INTERVAL '30 days'
        GROUP BY 
            OwnerUserId
    ) rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000
),
PostOverview AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROUND(AVG(v.Score), 2) AS AverageScore,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.ClosedDate IS NULL -- Only open questions
    GROUP BY 
        p.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBadges,
    tu.TotalRecentPosts,
    po.Title,
    po.CreationDate,
    po.AverageScore,
    po.ViewCount
FROM 
    TopUsers tu
JOIN 
    PostOverview po ON tu.UserId = po.OwnerDisplayName
ORDER BY 
    tu.Reputation DESC,
    po.AverageScore DESC
LIMIT 10;
