WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown'
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        AVG(CHAR_LENGTH(p.Body)) AS AvgBodyLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
),
BadgesEarned AS (
    SELECT 
        UserId,
        COUNT(Id) AS TotalBadges,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    uReputation.Reputation,
    ps.PostId,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.AvgBodyLength,
    be.TotalBadges,
    be.BadgeNames
FROM 
    Users u
LEFT JOIN 
    UserReputation uReputation ON u.Id = uReputation.UserId
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    BadgesEarned be ON u.Id = be.UserId
WHERE 
    uReputation.Reputation IS NOT NULL
    AND (u.CreationDate > DATEADD(YEAR, -2, GETDATE()) OR uReputation.Reputation > 500)
ORDER BY 
    uReputation.Reputation DESC, ps.CommentCount DESC, ps.UpVoteCount DESC
OFFSET 50 ROWS FETCH NEXT 50 ROWS ONLY;

-- Special cases and corner logic
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'No Posts'
        ELSE 'Has Posts'
    END AS PostStatus,
    COUNT(DISTINCT u.Id) AS UserCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
WHERE u.LastAccessDate IS NOT NULL 
GROUP BY PostStatus
HAVING COUNT(u.Reputation) > (SELECT AVG(Reputation) FROM Users);

-- Unusual aggregate case using NULL handling
WITH FilteredPosts AS (
    SELECT 
        p.Id,
        COALESCE(p.Score, 0) AS ValidScore
    FROM Posts p
    WHERE p.OwnerUserId IS NOT NULL
)
SELECT 
    SUM(ValidScore) AS TotalValidScore,
    COUNT(*) AS TotalPosts,
    SUM(ValidScore) / NULLIF(COUNT(*), 0) AS AverageScorePerPost
FROM FilteredPosts
WHERE ValidScore > 0;

