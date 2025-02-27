WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 AND 
        p.CreationDate > NOW() - INTERVAL '1 YEAR'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosedQuestions,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.PostId END) AS DeletedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalQuestions,
    us.ClosedQuestions,
    us.DeletedQuestions,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    rp.Score AS LatestPostScore,
    rp.ViewCount AS LatestPostViews
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.TotalQuestions > 0 
ORDER BY 
    us.TotalQuestions DESC, 
    us.ClosedQuestions ASC
LIMIT 10;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM Users WHERE Reputation > 1000) THEN 'Active Users'
        ELSE 'New Users'
    END AS UserType, 
    COUNT(*) AS NumberOfUsers
FROM 
    Users
WHERE 
    LastAccessDate > NOW() - INTERVAL '30 DAYS';

SELECT 
    p.Id AS PostId,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.ViewCount IS NOT NULL
GROUP BY 
    p.Id
HAVING 
    COUNT(DISTINCT c.Id) > 0 
HAVING 
    SUM(v.VoteTypeId) IS NOT NULL
ORDER BY 
    p.ViewCount DESC;

SELECT 
    u.DisplayName,
    ARRAY_AGG(DISTINCT t.TagName) AS UserTags 
FROM 
    Users u 
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    u.Reputation < 100
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT t.TagName) > 0;
