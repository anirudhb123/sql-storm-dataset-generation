
WITH UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionsCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswersCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes,
        Downvotes,
        PostsCount,
        QuestionsCount,
        AnswersCount,
        TotalScore,
        (@rank := @rank + 1) AS Rank
    FROM UserPerformance, (SELECT @rank := 0) r
    ORDER BY TotalScore DESC
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.Text,
        p.Title,
        (@row_number := IF(@current_post = ph.PostId, @row_number + 1, 1)) AS RecentEdit,
        @current_post := ph.PostId
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    CROSS JOIN (SELECT @row_number := 0, @current_post := NULL) r
    WHERE ph.CreationDate > (NOW() - INTERVAL 30 DAY)
    ORDER BY ph.PostId, ph.CreationDate DESC
)
SELECT 
    tu.DisplayName,
    tu.Upvotes,
    tu.Downvotes,
    tu.PostsCount,
    tu.QuestionsCount,
    tu.AnswersCount,
    tu.TotalScore,
    rph.PostId,
    rph.RecentEdit,
    rph.Title,
    rph.Comment,
    rph.Text,
    CASE 
        WHEN rph.UserId IS NULL THEN 'No Edits'
        ELSE 'Edited'
    END AS EditStatus
FROM TopUsers tu
LEFT JOIN RecentPostHistory rph ON tu.UserId = rph.UserId
WHERE tu.Rank <= 10
ORDER BY tu.Rank, rph.PostId;
