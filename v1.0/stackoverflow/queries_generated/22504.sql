WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Title,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
PostStatistics AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        AVG(b.Class) AS AverageBadgeClass, 
        SUM(CASE WHEN b.Date >= NOW() - INTERVAL '1 year' THEN 1 ELSE 0 END) AS RecentBadges
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(ps.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(ps.DownVotes), 0) AS TotalDownVotes,
        COALESCE(AVG(ps.AverageBadgeClass), NULL) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AvgBadgeClass,
    rp.PostId,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViewCount
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    us.TotalUpVotes > 10 
    AND (us.TotalComments > 5 OR us.AvgBadgeClass > 2)
ORDER BY 
    us.TotalUpVotes DESC, 
    us.TotalComments DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    DISTINCT u.Id,
    u.DisplayName,
    0 AS TotalComments,
    0 AS TotalUpVotes,
    0 AS TotalDownVotes,
    NULL AS AvgBadgeClass,
    NULL AS TopPostId,
    NULL AS TopPostTitle,
    NULL AS TopPostScore,
    NULL AS TopPostViewCount
FROM 
    Users u
WHERE 
    u.Reputation < 50 
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id
    )
ORDER BY 
    u.Reputation ASC;
