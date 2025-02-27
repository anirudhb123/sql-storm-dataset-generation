WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBounty,
        UpVotes,
        DownVotes,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserActivity
    JOIN Users ON UserActivity.UserId = Users.Id
    WHERE Reputation > 1000
)

SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.TotalBounty,
    u.UpVotes,
    u.DownVotes,
    u.TotalViews
FROM HighReputationUsers u
WHERE u.Rank <= 10
ORDER BY u.UpVotes DESC, u.TotalPosts DESC;

SELECT DISTINCT 
    'Bounty Contributions' AS ContributionType,
    u.DisplayName,
    COALESCE(b.TotalBounty, 0) AS TotalBounty
FROM Users u
LEFT JOIN (
    SELECT 
        UserId,
        SUM(BountyAmount) AS TotalBounty
    FROM Votes
    WHERE VoteTypeId IN (8, 9) -- Bounty Start and Close
    GROUP BY UserId
) b ON u.Id = b.UserId
WHERE COALESCE(b.TotalBounty, 0) > 0
ORDER BY TotalBounty DESC;

SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    MAX(v.CreationDate) AS LastVoteDate,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS Status,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN LATERAL (
    SELECT 
        tag.TagName
    FROM Tags tag
    WHERE tag.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int[]))
) t ON TRUE
WHERE p.CreationDate < NOW() - INTERVAL '1 year'
GROUP BY p.Title
HAVING COUNT(c.Id) > 0
ORDER BY CommentCount DESC;
