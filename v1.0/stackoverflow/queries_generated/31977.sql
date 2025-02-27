WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastChangeDate,
        STRING_AGG(ph.Comment, ', ') AS ChangeComments
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Considering close, reopen, delete, undelete
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
EnhancedUserStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalAnswers,
        ups.TotalQuestions,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ups.TotalBadges,
        COUNT(phc.PostId) AS TotalChanges,
        SUM(CASE WHEN phc.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosed,
        SUM(CASE WHEN phc.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopened,
        STRING_AGG(DISTINCT phc.ChangeComments, '; ') AS CommentsOnChanges
    FROM UserPostStats ups
    LEFT JOIN PostHistoryCTE phc ON ups.UserId IN (
        SELECT u.Id
        FROM Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        WHERE p.Id = phc.PostId
    )
    GROUP BY ups.UserId, ups.DisplayName
)
SELECT 
    eus.DisplayName,
    eus.TotalPosts,
    eus.TotalAnswers,
    eus.TotalQuestions,
    eus.TotalUpVotes,
    eus.TotalDownVotes,
    eus.TotalBadges,
    eus.TotalChanges,
    eus.TotalClosed,
    eus.TotalReopened,
    COALESCE(eus.CommentsOnChanges, 'No comments') AS CommentsOnChanges
FROM EnhancedUserStats eus
ORDER BY eus.TotalPosts DESC
LIMIT 100;
