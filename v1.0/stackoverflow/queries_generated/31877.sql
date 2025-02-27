WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, 0 AS Level 
    FROM Tags 
    WHERE Id IS NOT NULL
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, Level + 1
    FROM Tags t
    JOIN RecursiveTagHierarchy rth ON t.ExcerptPostId = rth.Id
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS RevisionCount
        FROM PostHistory
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.Location,
    us.TotalVotes,
    us.UpVotes,
    us.DownVotes,
    ub.BadgeCount,
    ub.Badges,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.RevisionCount,
    ps.CommentCount,
    ps.TotalBounties
FROM Users u
LEFT JOIN UserVoteStats us ON u.Id = us.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStatistics ps ON ps.PostRank <= 5 AND ps.PostId IN (
    SELECT Id 
    FROM Posts 
    WHERE OwnerUserId = u.Id
)
LEFT JOIN (
    SELECT DISTINCT Tags.Id, Tags.TagName
    FROM Tags
    JOIN Posts ON Tags.ExcerptPostId = Posts.Id
) t ON ps.PostId = t.Id
GROUP BY u.Id, u.DisplayName, u.Reputation, u.Location, us.TotalVotes, us.UpVotes, us.DownVotes, ub.BadgeCount, ub.Badges, ps.PostId, ps.Title, ps.CreationDate, ps.RevisionCount, ps.CommentCount, ps.TotalBounties
ORDER BY u.Reputation DESC, ps.TotalBounties DESC;
