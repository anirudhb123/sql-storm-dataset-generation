WITH UserPerformance AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    WHERE u.Reputation IS NOT NULL AND u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 10, 12)
),
FinalOutput AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.Reputation,
        tq.Title AS TopQuestionTitle,
        tq.Score AS QuestionScore,
        tq.UpVotes,
        tq.DownVotes,
        ph.UserId AS LastEditorId,
        ph.CreationDate AS LastEditDate,
        ph.PostHistoryTypeId AS LastEditType
    FROM UserPerformance up
    JOIN TopQuestions tq ON tq.Rank <= 10
    LEFT JOIN RecentPostHistory ph ON tq.PostId = ph.PostId AND ph.RecentEditRank = 1
)
SELECT 
    f.*,
    COALESCE((SELECT STRING_AGG(DISTINCT c.Text, ', ') 
              FROM Comments c 
              WHERE c.PostId IN (SELECT tq.PostId FROM TopQuestions tq WHERE tq.Rank <= 10)), 'No Comments') AS CommentSummary,
    CASE 
        WHEN f.Reputation > 1000 THEN 'High Reputation User'
        WHEN f.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User'
    END AS ReputationCategory
FROM FinalOutput f
WHERE f.Reputation > 0
ORDER BY f.QuestionScore DESC, f.LastEditDate DESC;
