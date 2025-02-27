
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseReopenCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CloseReopenCount,
        BadgeCount,
        @rank := @rank + 1 AS Rank
    FROM UserPostStats, (SELECT @rank := 0) r
    WHERE QuestionCount > 0
    ORDER BY (QuestionCount + AnswerCount) DESC, BadgeCount DESC
),
FilteredUsers AS (
    SELECT 
        *,
        LEAD(DisplayName) OVER (ORDER BY Rank) AS NextUserDisplayName
    FROM RankedUsers
    WHERE BadgeCount > 0 AND CloseReopenCount >= 1
)
SELECT 
    f.DisplayName AS CurrentUser,
    f.NextUserDisplayName,
    f.QuestionCount,
    f.AnswerCount,
    f.BadgeCount,
    f.CloseReopenCount,
    CASE 
        WHEN f.CloseReopenCount IS NULL THEN 'No actions taken'
        ELSE CONCAT('Post has been ', CASE 
            WHEN f.CloseReopenCount > 1 THEN 'closed and reopened multiple times'
            ELSE 'closed and reopened once'
        END)
    END AS ClosureStatus,
    (SELECT COUNT(*) FROM Tags t WHERE t.Count > 1000) AS PopularTagCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS PopularTags
FROM FilteredUsers f
LEFT JOIN Posts p ON f.UserId = p.OwnerUserId
LEFT JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
GROUP BY f.UserId, f.DisplayName, f.NextUserDisplayName, f.QuestionCount, f.AnswerCount, f.BadgeCount, f.CloseReopenCount, f.Rank
HAVING COUNT(DISTINCT t.Id) > 2
ORDER BY f.Rank
LIMIT 10 OFFSET 5;
