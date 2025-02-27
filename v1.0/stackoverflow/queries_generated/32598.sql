WITH RecursiveUserHierarchy AS (
    SELECT Id, Reputation, CreationDate, 1 AS Level
    FROM Users
    WHERE Id = (SELECT MIN(Id) FROM Users)  -- Starting with the user with the lowest Id

    UNION ALL

    SELECT u.Id, u.Reputation, u.CreationDate, Level + 1
    FROM Users u
    JOIN RecursiveUserHierarchy r ON u.Id = r.Id + 1  -- Hypothetical relationship for demonstration
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Assuming VoteTypeId = 2 is an upvote
        SUM(v.VoteTypeId = 3) AS DownVotes  -- VoteTypeId = 3 is a downvote
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.CommentCount,
        RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank
    FROM PostStatistics ps
    WHERE ps.CommentCount > 10  -- Filter for posts with more than 10 comments
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ActiveBadges AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount
    FROM UserBadges ub
    WHERE ub.BadgeCount > 5  -- Filtering users with more than 5 badges
),
FinalResults AS (
    SELECT 
        p.Title, 
        p.Score, 
        u.DisplayName, 
        ub.BadgeCount,
        ps.CommentCount
    FROM TopPosts p
    JOIN ActiveBadges ub ON p.Score >= 10  -- Ensure only top posts with significant score
    JOIN Users u ON u.Id IN (
        SELECT v.UserId
        FROM Votes v 
        WHERE v.PostId = p.PostId 
        GROUP BY v.UserId
    )
)
SELECT 
    f.Title,
    f.Score,
    f.DisplayName,
    f.BadgeCount,
    f.CommentCount
FROM FinalResults f
ORDER BY f.Score DESC, f.CommentCount DESC  -- Ordering by Score and CommentCount
LIMIT 100;  -- Limiting to top 100 records


