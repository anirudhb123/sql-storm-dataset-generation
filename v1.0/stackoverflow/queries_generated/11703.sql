WITH Benchmark AS (
  SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes
  FROM 
    Posts p
  LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
  LEFT JOIN 
    Comments c ON p.Id = c.PostId
  LEFT JOIN 
    Votes v ON p.Id = v.PostId
  WHERE 
    p.PostTypeId = 1 -- Filter for Questions
  GROUP BY 
    p.Id, u.DisplayName
)
SELECT 
  *,
  (UpVotes - DownVotes) AS NetVotes
FROM 
  Benchmark
ORDER BY 
  ViewCount DESC, Score DESC
LIMIT 10;
