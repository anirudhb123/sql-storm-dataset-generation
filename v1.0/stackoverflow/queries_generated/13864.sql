-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostTypesStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Name
),
VotesStats AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        VoteTypes vt
    LEFT JOIN 
        Votes v ON vt.Id = v.VoteTypeId
    GROUP BY 
        vt.Name
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.TotalScore,
    u.TotalViews,
    u.BadgeCount,
    p.PostType,
    p.PostCount AS PostTypeCount,
    p.TotalScore AS PostTypeTotalScore,
    p.TotalViews AS PostTypeTotalViews,
    v.VoteType,
    v.VoteCount,
    v.UpVoteCount,
    v.DownVoteCount
FROM 
    UserStats u
CROSS JOIN 
    PostTypesStats p
CROSS JOIN 
    VotesStats v
ORDER BY 
    u.TotalScore DESC, 
    p.TotalScore DESC, 
    v.VoteCount DESC;
