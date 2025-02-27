WITH UserVoteStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(DISTINCT PostId) AS UniquePostVotes
    FROM Votes
    GROUP BY UserId
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        MAX(p.CreationDate) AS LastPostDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY MAX(p.CreationDate) DESC) AS RecentPostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    WHERE u.Reputation > 1000  -- Only consider users with reputation above 1000
    GROUP BY u.Id
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(la.LastActivityDate, p.LastActivityDate) AS LastActivityDate,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AcceptanceStatus
    FROM Posts p
    LEFT JOIN LATERAL (
        SELECT COUNT(c.Id) AS CommentCount
        FROM Comments c
        WHERE c.PostId = p.Id
    ) c ON TRUE
    LEFT JOIN LATERAL (
        SELECT MAX(LastActivityDate) 
        FROM Posts 
        WHERE ParentId = p.Id
    ) la ON TRUE
)
SELECT 
    ua.DisplayName,
    ua.TotalBounties,
    ua.RecentPostRank,
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.ViewCount,
    pi.CommentCount,
    pi.LastActivityDate,
    pi.AcceptanceStatus,
    COALESCE(uv.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(uv.DownVoteCount, 0) AS TotalDownVotes
FROM RecentActivity ua
JOIN PostInteraction pi ON ua.UserId = pi.OwnerUserId
LEFT JOIN UserVoteStats uv ON ua.UserId = uv.UserId
WHERE ua.RecentPostRank = 1
ORDER BY ua.TotalBounties DESC, pi.LastActivityDate DESC;
