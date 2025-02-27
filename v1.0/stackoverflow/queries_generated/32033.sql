WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        1 AS Level,
        u.CreationDate,
        u.Location
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Starting point for high-reputation users

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        urc.Level + 1,
        u.CreationDate,
        u.Location
    FROM 
        Users u
    JOIN
        UserReputationCTE urc ON u.Reputation > urc.Reputation
    WHERE 
        urc.Level < 5 -- Limiting the recursion depth
)
SELECT 
    ur.Id,
    ur.DisplayName,
    ur.Reputation,
    ur.Level,
    COUNT(DISTINCT p.Id) AS PostsCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AverageBounty
FROM 
    UserReputationCTE ur
LEFT JOIN 
    Posts p ON ur.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    ur.Id, ur.DisplayName, ur.Reputation, ur.Level
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 posts
ORDER BY 
    ur.Reputation DESC, 
    ur.Level ASC 
LIMIT 10;

-- Finding the most linked posts
WITH PostLinkCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    p.Id,
    p.Title,
    p.ViewCount,
    COALESCE(plc.LinkCount, 0) AS TotalLinks
FROM 
    Posts p
LEFT JOIN 
    PostLinkCounts plc ON p.Id = plc.PostId 
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts from the last year
ORDER BY 
    TotalLinks DESC, 
    p.Score DESC
LIMIT 5;

-- Analyzing Post History Types
SELECT 
    p.Id,
    p.Title,
    p.Body,
    p.CreationDate,
    ARRAY_AGG(DISTINCT pht.Name) AS PostHistoryTypes
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    p.Id, p.Title, p.Body, p.CreationDate
HAVING 
    COUNT(ph.Id) > 10 -- Filtering for posts with more than 10 history records
ORDER BY 
    p.CreationDate DESC;
