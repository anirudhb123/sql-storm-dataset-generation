WITH RecursiveUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u 
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentCloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
    AVG(u.Reputation) AS AverageReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags,
    MAX(p.LastActivityDate) AS LastActive,
    (SELECT COUNT(DISTINCT cp.PostId) 
     FROM RecentClosedPosts cp 
     WHERE cp.UserId = u.Id) AS ClosedPostsCount,
    (SELECT STRING_AGG(DISTINCT up.Title, '; ') 
     FROM RecursiveUserPosts up 
     WHERE up.OwnerUserId = u.Id AND up.UserPostRank <= 3) AS RecentUserQuestions
FROM 
    TopUsers u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')))
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.UserId, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalScore DESC
LIMIT 10;
