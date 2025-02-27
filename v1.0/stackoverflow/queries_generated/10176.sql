-- Performance Benchmarking Query

-- This query retrieves the count of different post types along with the average score and views for each post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- This query calculates the total number of votes per post and the average votes per user.
SELECT 
    p.Id AS PostId,
    COUNT(v.Id) AS TotalVotes,
    COALESCE(AVG(v.voteCountPerUser), 0) AS AverageVotesPerUser
FROM 
    Posts p
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(Id) AS voteCountPerUser 
     FROM 
        Votes 
     GROUP BY 
        PostId, UserId) v ON p.Id = v.PostId
GROUP BY 
    p.Id
ORDER BY 
    TotalVotes DESC;

-- This query evaluates user activity by calculating the average reputation and post count per user.
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC, AverageReputation DESC;

-- This query checks post history changes by counting the number of edits and types of changes made to posts.
SELECT 
    p.Id AS PostId,
    COUNT(ph.Id) AS EditCount,
    STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    p.Id
ORDER BY 
    EditCount DESC;
