WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM Posts p
    WHERE p.ParentId IS NULL -- Start from the root posts

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        r.Level + 1,
        CAST(r.Path + ' -> ' + p.Title AS VARCHAR(MAX))
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.Upvotes, 0) AS Upvotes,
        COALESCE(v.Downvotes, 0) AS Downvotes,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(pb.UserId, -1) AS TopVoterId, -- Assuming -1 indicates no top voter
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.TotalVotes DESC) AS VoterRank
    FROM Posts p
    LEFT JOIN PostVotes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            p.Id AS PostId,
            v.UserId
        FROM Votes v
        JOIN Posts p ON v.PostId = p.Id
        WHERE v.VoteTypeId = 2 -- Only interested in UpVotes for the top voter
    ) pb ON p.Id = pb.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerName,
    b.BadgeCount,
    b.Badges,
    ps.Upvotes,
    ps.Downvotes,
    ps.TotalVotes,
    r.Level,
    r.Path
FROM RecursivePostHierarchy r
JOIN Posts p ON r.PostId = p.Id
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserBadges b ON u.Id = b.UserId
LEFT JOIN PostStatistics ps ON r.PostId = ps.PostId
WHERE 
    (u.Reputation >= 1000 OR ps.Upvotes > 10) -- Returning only users with high reputation or posts with significant upvotes
ORDER BY r.Level, ps.TotalVotes DESC, r.PostCreationDate;
