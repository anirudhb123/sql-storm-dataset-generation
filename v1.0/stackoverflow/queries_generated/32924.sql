WITH RecursiveTagHierarchy AS (
  SELECT 
    Id,
    TagName,
    Count,
    ExcerptPostId,
    WikiPostId,
    1 AS Level
  FROM 
    Tags
  WHERE 
    IsModeratorOnly = 1
  
  UNION ALL
  
  SELECT 
    t.Id,
    t.TagName,
    t.Count,
    t.ExcerptPostId,
    t.WikiPostId,
    th.Level + 1
  FROM 
    Tags t
  INNER JOIN 
    RecursiveTagHierarchy th ON t.WikiPostId = th.ExcerptPostId
),
PostVoteStats AS (
  SELECT
    p.Id AS PostId,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
  FROM 
    Posts p
  LEFT JOIN 
    Votes v ON p.Id = v.PostId
  WHERE 
    p.LastActivityDate >= NOW() - INTERVAL '30 days'
  GROUP BY 
    p.Id
),
TopUsers AS (
  SELECT 
    u.Id,
    u.DisplayName,
    SUM(v.BountyAmount) AS TotalBounty,
    RANK() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS UserRank
  FROM 
    Users u
  LEFT JOIN 
    Votes v ON u.Id = v.UserId
  WHERE 
    v.VoteTypeId = 8 -- BountyStart votes only
  GROUP BY 
    u.Id, u.DisplayName
),
FilteredPosts AS (
  SELECT 
    p.Id,
    p.Title,
    p.ViewCount,
    pts.TotalVotes,
    pts.UpVotes,
    pts.DownVotes,
    th.Level AS TagLevel
  FROM 
    Posts p
  LEFT JOIN 
    PostVoteStats pts ON p.Id = pts.PostId
  LEFT JOIN 
    RecursiveTagHierarchy th ON th.ExcerptPostId = p.Id
  WHERE 
    pts.TotalVotes IS NOT NULL
    AND p.CreationDate >= NOW() - INTERVAL '6 months'
),
FinalOutput AS (
  SELECT 
    fp.Title,
    fp.ViewCount,
    fp.TotalVotes,
    fp.UpVotes,
    fp.DownVotes,
    tu.DisplayName AS TopUser,
    tu.TotalBounty,
    fp.TagLevel
  FROM 
    FilteredPosts fp
  LEFT JOIN 
    TopUsers tu ON fp.TagLevel = 1  -- considering only top users for top Tags
  ORDER BY 
    fp.UpVotes DESC,
    fp.ViewCount DESC
)
SELECT 
  Title,
  ViewCount,
  TotalVotes,
  UpVotes,
  DownVotes,
  COALESCE(TopUser, 'No Top Users') AS TopUser,
  COALESCE(TotalBounty, 0) AS TotalBounty,
  TagLevel
FROM 
  FinalOutput
WHERE 
  TotalVotes > 5
ORDER BY 
  TagLevel,
  UpVotes DESC
LIMIT 10;
