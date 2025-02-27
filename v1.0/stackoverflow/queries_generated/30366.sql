WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Start with root posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p 
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PollResults AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN Votes.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Posts 
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 YEAR' -- Posts created in the last year
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(Id) > 10 -- Only include users with more than 10 posts
)
SELECT 
    u.DisplayName,
    COALESCE(NULLIF(u.Location, ''), 'Not specified') AS Location,
    COALESCE(badge_count.BadgeCount, 0) AS BadgeCount,
    COALESCE(topUsers.PostCount, 0) AS RecentPostCount,
    COALESCE(topUsers.TotalScore, 0) AS RecentTotalScore,
    SUM(COALESCE(pr.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(pr.DownVotes, 0)) AS TotalDownVotes,
    COUNT(*) AS TotalPosts,
    STRING_AGG(DISTINCT p.Title, ', ') AS RelatedPosts
FROM 
    Users u
LEFT JOIN 
    PollResults pr ON pr.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    TopUsers topUsers ON topUsers.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) AS badge_count ON badge_count.UserId = u.Id
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.Id = p.Id 
WHERE 
    u.Reputation > 50 -- Users with reputation greater than 50
GROUP BY 
    u.Id, u.DisplayName, u.Location, badge_count.BadgeCount, topUsers.PostCount, topUsers.TotalScore
ORDER BY 
    TotalPosts DESC, u.DisplayName;
