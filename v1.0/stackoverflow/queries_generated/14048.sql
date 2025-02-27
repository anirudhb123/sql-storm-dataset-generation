-- Performance Benchmarking Query

-- Selecting the count of posts grouped by PostType and the average score of posts
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Focusing on the last year
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Benchmarking the users' activity: Users' reputation and their number of posts
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS UserPostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0  -- Only include users with at least one post
ORDER BY 
    Reputation DESC, UserPostCount DESC 
LIMIT 10;

-- Analyzing the average number of votes received per post type
SELECT 
    vt.Name AS VoteTypeName,
    COUNT(v.Id) AS VoteCount,
    AVG(v.CreationDate) AS AvgVoteCreationDate,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
JOIN 
    Posts p ON v.PostId = p.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;

-- Fetching all closed posts with their respective close reason
SELECT 
    p.Title,
    p.CreationDate,
    ph.CreationDate AS ClosedDate,
    crt.Name AS CloseReason
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id  -- Assuming Comment holds the CloseReasonId
WHERE 
    ph.PostHistoryTypeId = 10  -- Only closed posts
ORDER BY 
    ClosedDate DESC
LIMIT 100;
