WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(a.Id) AS AcceptedAnswerCount
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.OwnerUserId
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LatestEdit,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edits to title, body, or tags
    AND ph.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY ph.PostId
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        COALESCE(ue.EditCount, 0) AS EditCount,
        COALESCE(ue.LatestEdit, NULL) AS LatestEdit,
        COALESCE(ue.EditComments, 'No edits') AS EditComments,
        COALESCE(a.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        CASE 
            WHEN p.ViewCount > 1000 THEN 'High Views'
            WHEN p.ViewCount IS NULL THEN 'Unknown Views'
            ELSE 'Low Views'
        END AS ViewCategory
    FROM Posts p
    LEFT JOIN RecentPostEdits ue ON p.Id = ue.PostId
    LEFT JOIN AcceptedAnswers a ON p.Id = a.PostId
)
SELECT 
    ps.PostId,
    ps.EditCount,
    ps.LatestEdit,
    ps.EditComments,
    ps.AcceptedAnswerCount,
    CASE 
        WHEN uv.UpVotes > 10 THEN 'Popular User'
        ELSE 'Regular User'
    END AS UserType,
    ps.ViewCategory,
    CONCAT('Post ID: ', ps.PostId, ', Edited: ', ps.EditCount, ' times, Views: ', ps.ViewCategory) AS PostSummary
FROM PostStatistics ps
JOIN Users u ON ps.PostId = u.Id
LEFT JOIN UserVoteCounts uv ON u.Id = ps.PostId
WHERE ps.AcceptedAnswerCount > 0
ORDER BY ps.LatestEdit DESC NULLS LAST, ps.EditCount DESC;
