WITH RankedPosts AS (
  SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.Tags,
    u.DisplayName AS Owner,
    p.CreationDate,
    ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
  FROM 
    Posts p
  JOIN 
    Users u ON p.OwnerUserId = u.Id
  WHERE 
    p.PostTypeId = 1  -- Filter for questions only
    AND p.Score > 0   -- Only include questions with positive scores
),

TagStatistics AS (
  SELECT 
    unnest(string_to_array(p.Tags, '><')) AS Tag,
    COUNT(*) AS Count,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers
  FROM 
    Posts p
  WHERE 
    p.PostTypeId = 1  -- Questions only
  GROUP BY 
    Tag
),

ActiveUserActivity AS (
  SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END) AS DownVotes
  FROM 
    Users u
  JOIN 
    Votes v ON u.Id = v.UserId
  WHERE 
    u.Reputation > 100  -- Active users with reputation above 100
  GROUP BY 
    u.Id
)

SELECT 
  rp.PostId, 
  rp.Title, 
  rp.Body, 
  rp.Owner, 
  ts.Tag, 
  ts.Count AS TagCount,
  ts.AverageScore,
  ts.TotalViews,
  ts.TotalAnswers,
  aua.UserName AS ActiveUser,
  aua.VoteCount AS ActivityCount,
  aua.UpVotes, 
  aua.DownVotes
FROM 
  RankedPosts rp
JOIN 
  TagStatistics ts ON rp.Tags LIKE '%' || ts.Tag || '%'
LEFT JOIN 
  ActiveUserActivity aua ON rp.OwnerUserId = aua.UserId
WHERE 
  rp.Rank <= 5  -- Top 5 questions per tag
ORDER BY 
  ts.Count DESC, 
  ts.AverageScore DESC;
