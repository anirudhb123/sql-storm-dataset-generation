WITH RECURSIVE UserRankings AS (
    SELECT Id, Reputation, CreationDate,
           RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation > 0
),
AnswerStats AS (
    SELECT p.Id AS PostId,
           COUNT(c.Id) AS CommentCount,
           COUNT(DISTINCT a.Id) AS AnswerCount,
           AVG(a.Score) AS AvgAnswerScore
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           COUNT(*) AS HistoryCount,
           MAX(CreationDate) AS LastEditDate,
           STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 10, 11)
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
TopTags AS (
    SELECT Tags.TagName,
           COUNT(*) AS PostCount
    FROM Posts p
    JOIN STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t(TagName)
    GROUP BY Tags.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
FinalOutput AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           ur.Rank,
           ps.PostId,
           ps.CommentCount,
           ps.AnswerCount,
           ps.AvgAnswerScore,
           (SELECT COUNT(*) FROM Badges WHERE UserId = u.Id) AS BadgeCount,
           th.HistoryCount,
           th.LastEditDate,
           th.Editors,
           tt.TagName
    FROM Users u
    JOIN UserRankings ur ON u.Id = ur.Id
    LEFT JOIN AnswerStats ps ON u.Id = ps.PostId
    LEFT JOIN PostHistoryDetails th ON ps.PostId = th.PostId
    LEFT JOIN TopTags tt ON tt.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(STRING_AGG(DISTINCT p.Tags, ', '), 2, LENGTH(STRING_AGG(DISTINCT p.Tags, ', ')) - 2), '><')))
                                            FROM Posts p WHERE p.OwnerUserId = u.Id)
    WHERE u.Reputation > 100
)
SELECT *
FROM FinalOutput
ORDER BY Reputation DESC, Rank, TagName;
