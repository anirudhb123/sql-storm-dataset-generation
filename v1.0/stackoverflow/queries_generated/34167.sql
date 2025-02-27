WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation > 0
),
TopUsers AS (
    SELECT Id, Reputation
    FROM UserReputation
    WHERE Rank <= 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        COALESCE(p.ANSWERCOUNT, 0) AS AnswerCount,
        COALESCE(ph.CLOSED_COUNT, 0) AS ClosedCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CLOSED_COUNT
        FROM PostHistory
        WHERE PostHistoryTypeId = 10
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.ANSWERCOUNT
),
HighScorePosts AS (
    SELECT PostId, Title, Score, ClosedCount, 
           RANK() OVER (PARTITION BY ClosedCount ORDER BY Score DESC) AS ScoreRank
    FROM PostStats
    WHERE Score > 5
),
FilteredPosts AS (
    SELECT hp.PostId, hp.Title, hp.Score, hp.ClosedCount
    FROM HighScorePosts hp
    WHERE hp.ScoreRank <= 5
),
UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        ub.BadgeCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM FilteredPosts fp
    LEFT JOIN UserBadges ub ON ub.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    COALESCE(fr.BadgeCount, 0) AS BadgeCount,
    fr.UpVotes,
    fr.DownVotes,
    CASE 
        WHEN fr.Score > 20 THEN 'High Score' 
        WHEN fr.Score BETWEEN 10 AND 20 THEN 'Medium Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM FinalResults fr
ORDER BY fr.Score DESC;
