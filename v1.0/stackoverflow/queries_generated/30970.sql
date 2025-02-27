WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1 AS Level
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    LEFT JOIN PostVoteStats vs ON p.Id = vs.PostId
    WHERE p.PostTypeId = 1 -- Only considering Questions
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(COALESCE(vs.UpVotes, 0)) AS AvgUserUpVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostVoteStats vs ON p.Id = vs.PostId
    GROUP BY u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.AcceptedAnswers,
    up.Title AS TopPostTitle,
    up.CreationDate AS TopPostCreationDate,
    up.ViewCount AS TopPostViewCount,
    up.UpVotes AS TopPostUpVotes,
    up.DownVotes AS TopPostDownVotes,
    COALESCE(bc.BadgeCount, 0) AS UserBadgeCount,
    r.Level AS PostHierarchyLevel
FROM UserPostStats ups
JOIN TopPosts up ON ups.UserId = up.OwnerUserId
LEFT JOIN UserBadgeCounts bc ON ups.UserId = bc.UserId
JOIN RecursivePostHierarchy r ON up.PostId = r.PostId
WHERE ups.PostCount > 0
ORDER BY ups.PostCount DESC, up.ViewCount DESC
LIMIT 10;
