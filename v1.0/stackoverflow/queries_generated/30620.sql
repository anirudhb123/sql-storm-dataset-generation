WITH RECURSIVE UserPosts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
), 
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (6, 10, 12) THEN 1 END) AS CloseVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ph.Comment ORDER BY ph.CreationDate) AS HistoryComments,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalClosedPosts,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    COALESCE(pv.CloseVotes, 0) AS CloseVotes,
    phs.HistoryComments,
    phs.LastEditDate
FROM UserPosts u
LEFT JOIN PostVoteSummary pv ON u.TotalPosts > 0 AND pv.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId LIMIT 1)
LEFT JOIN PostHistorySummary phs ON phs.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId LIMIT 1)
WHERE u.TotalPosts > 0
ORDER BY u.TotalPosts DESC, u.TotalQuestions DESC, u.TotalAnswers DESC;

