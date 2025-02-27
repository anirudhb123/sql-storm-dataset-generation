WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, v.UpVotes, v.DownVotes, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank
    FROM PostStatistics ps
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
EnhancedPostInfo AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        pp.UpVotes,
        pp.DownVotes,
        pp.CommentCount,
        ur.DisplayName AS OwnerDisplayName,
        ub.BadgeCount
    FROM TopPosts pp
    JOIN Posts p ON pp.PostId = p.Id
    JOIN Users ur ON p.OwnerUserId = ur.Id
    LEFT JOIN UserBadges ub ON ur.Id = ub.UserId
)
SELECT 
    epi.Title,
    epi.Score,
    epi.ViewCount,
    epi.UpVotes,
    epi.DownVotes,
    epi.CommentCount,
    CASE 
        WHEN epi.BadgeCount IS NULL THEN 'No Badges' 
        ELSE CAST(epi.BadgeCount AS VARCHAR(10)) + ' Badge(s)' 
    END AS BadgeInfo,
    ur.ReputationRank
FROM EnhancedPostInfo epi
JOIN UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = epi.PostId)
WHERE epi.ScoreRank <= 10 
ORDER BY epi.Score DESC, epi.ViewCount DESC;
