WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    CASE 
        WHEN tu.ViewRank < 11 THEN 'Top Viewers'
        ELSE 'Average Viewers'
    END AS ViewStatus,
    CASE 
        WHEN tu.ScoreRank < 11 THEN 'Top Scorers'
        ELSE 'Average Scorers'
    END AS ScoreStatus,
    COALESCE(b.BadgeCount, 0) AS NumberOfBadges
FROM 
    TopUsers tu
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON tu.UserId = b.UserId
WHERE 
    tu.PostCount > 0
ORDER BY 
    tu.TotalScore DESC, tu.TotalViews DESC
LIMIT 20;

WITH RECURSIVE ParentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        pp.Title,
        pp.OwnerUserId,
        pp.ParentId,
        p.Level + 1
    FROM 
        Posts pp
    INNER JOIN 
        ParentPosts p ON pp.ParentId = p.Id
)
SELECT 
    pp.Title,
    pp.Level,
    COUNT(c.Id) AS CommentCount
FROM 
    ParentPosts pp
LEFT JOIN 
    Comments c ON pp.Id = c.PostId
GROUP BY 
    pp.Title, pp.Level
HAVING 
    COUNT(c.Id) > 5
ORDER BY 
    pp.Level, pp.Title;

SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
    SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Id, pt.Name
HAVING 
    SUM(COALESCE(p.Score, 0)) > 1000
ORDER BY 
    AvgViews DESC;

SELECT 
    u.DisplayName,
    p.Title,
    p.CreatedDate,
    coalesce(v.UpVotes, 0) AS UpVotes,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.DownVotes, 0) AS DownVotes
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(Id) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON p.Id = c.PostId
WHERE 
    p.LastActivityDate >= NOW() - INTERVAL '30 days'
ORDER BY 
    UpVotes DESC, CommentCount DESC;

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(COALESCE(p.Score, 0)) AS AvgScore,
    (SELECT COUNT(*) FROM Posts WHERE CreationDate >= CURRENT_DATE - INTERVAL '1 month') AS RecentPosts
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    AvgScore DESC;

SELECT 
    p.Id,
    p.Title,

