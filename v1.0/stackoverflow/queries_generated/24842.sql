WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryMetrics AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS TotalEdits,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Only edits to title, body, and tags
    GROUP BY p.Id
),
ClosedPostMetrics AS (
    SELECT
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(ph.Id) AS CloseVoteCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.Comment
),
TopUsers AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.AverageReputation,
        COALESCE(ppm.TotalEdits, 0) AS TotalEdits,
        COALESCE(cpm.CloseVoteCount, 0) AS CloseVoteCount,
        ROW_NUMBER() OVER (ORDER BY ups.AverageReputation DESC) AS Rank
    FROM UserPostStats ups
    LEFT JOIN PostHistoryMetrics ppm ON ups.TotalPosts = ppm.TotalEdits
    LEFT JOIN ClosedPostMetrics cpm ON ppm.PostId = cpm.PostId
    WHERE ups.TotalPosts > 0
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AverageReputation,
    TotalEdits,
    CloseVoteCount,
    Rank
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;

-- Additionally, to showcase an unusual case, the following selects only users with a NULL CloseVoteCount:
SELECT 
    u.DisplayName,
    (SELECT COUNT(1) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
    (SELECT COUNT(1) FROM PostHistory ph WHERE ph.UserId = u.Id AND ph.PostHistoryTypeId = 10) AS CloseVotes
FROM Users u
WHERE u.Id NOT IN (SELECT DISTINCT UserId FROM Votes) 
AND NOT EXISTS (
    SELECT 1
    FROM ClosedPostMetrics cpm 
    WHERE cpm.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
);
