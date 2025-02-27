WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown' 
            WHEN u.Reputation < 1000 THEN 'Low' 
            WHEN u.Reputation BETWEEN 1000 AND 10000 THEN 'Medium' 
            ELSE 'High' 
        END AS Reputation_Level
    FROM Users u
), PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
), PostEngagement AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AnswerCount, 0) AS Answers,
        COALESCE(p.CommentCount, 0) AS Comments,
        COALESCE(vote_count.VoteCount, 0) AS VoteCount,
        window_rank.Rank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) AS vote_count ON p.Id = vote_count.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            RANK() OVER (ORDER BY COUNT(*) DESC) AS Rank
        FROM Comments
        GROUP BY PostId
    ) AS window_rank ON p.Id = window_rank.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
), DetailedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.Body,
        p.Score,
        ph.Comment AS CloseReason,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Open'
            ELSE 'Other'
        END AS Operation,
        STRING_AGG(ut.Reputation_Level, ', ') AS UserReputations
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    LEFT JOIN UserReputation ut ON ut.UserId = ph.UserId
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Considering only closed and opened posts
    GROUP BY ph.PostId, ph.UserId, ph.CreationDate, p.Title, p.Body, p.Score, ph.Comment
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    pe.Answers,
    pe.Comments,
    pe.VoteCount,
    dph.CloseReason,
    dph.Operation,
    ut.Reputation_Level
FROM Posts p
LEFT JOIN PostEngagement pe ON p.Id = pe.PostId
LEFT JOIN DetailedPostHistory dph ON p.Id = dph.PostId
LEFT JOIN UserReputation ut ON ut.UserId = p.OwnerUserId
WHERE p.Score > 0 
  AND pe.Rank < 10
  AND ut.Reputation_Level <> 'Unknown'
ORDER BY pe.VoteCount DESC, p.CreationDate DESC
LIMIT 50;

-- Bonus query to demonstrate NULL logic by checking for any NULLs in engagement metrics
SELECT
    p.Id AS PostId,
    COALESCE(pe.Answers, 0) AS Answers,
    COALESCE(pe.Comments, 0) AS Comments,
    CASE 
        WHEN pe.VoteCount IS NULL THEN 'No votes' 
        ELSE 'Votes present' 
    END AS VoteStatus
FROM Posts p
LEFT JOIN PostEngagement pe ON p.Id = pe.PostId
WHERE pe.Answers IS NULL OR pe.Comments IS NULL
LIMIT 30;
