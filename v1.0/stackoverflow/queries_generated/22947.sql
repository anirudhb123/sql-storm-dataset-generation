WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.DownVotes > 0 THEN 1 ELSE 0 END) AS DownVotedPosts,
        SUM(CASE WHEN p.FavoriteCount > 0 THEN 1 ELSE 0 END) AS FavoritedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorId,
        ph.CreationDate AS EditDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rnk
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13)
),
RecentPostEdits AS (
    SELECT 
        PostId,
        EditorId,
        EditDate,
        PostHistoryTypeId,
        Comment
    FROM PostHistoryData
    WHERE rnk = 1
),
CloseReasonDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.Reputation,
    us.Views,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.DownVotedPosts,
    us.FavoritedPosts,
    COALESCE(rpe.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(rpe.EditorId, -1) AS LastEditorId,
    cr.CloseReasons
FROM UserStats us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN RecentPostEdits rpe ON rpe.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN CloseReasonDetails cr ON cr.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE us.Reputation > 1000
ORDER BY us.Reputation DESC, LastEditDate DESC;
