WITH RecursiveTopTag AS (
    SELECT 
        Id,
        TagName,
        Count,
        1 AS Level
    FROM 
        Tags
    WHERE 
        IsRequired = 1
    
    UNION ALL
    
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        rt.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTopTag rt ON t.Count > rt.Count
)
,
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(p.Score * 1.0) AS AvgScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId
)
,
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.TagName,
    COUNT(DISTINCT ps.PostId) AS NumberOfPosts,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.UpVotes) - SUM(ps.DownVotes) AS NetVotes,
    SUM(ts.TotalViews) AS TotalViews,
    STRING_AGG(DISTINCT tu.DisplayName, ', ') AS TopUserNames
FROM 
    RecursiveTopTag t
LEFT JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT JOIN 
    PostStats ps ON p.Id = ps.PostId
LEFT JOIN 
    TopUsers tu ON ps.AcceptedAnswerId = tu.UserId
WHERE 
    ps.AvgScore > 3
GROUP BY 
    t.TagName
ORDER BY 
    NumberOfPosts DESC;
