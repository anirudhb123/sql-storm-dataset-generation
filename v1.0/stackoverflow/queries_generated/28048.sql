WITH TagStatistics AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN Posts.ViewCount IS NOT NULL THEN Posts.ViewCount ELSE 0 END) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM Tags
    LEFT JOIN Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%)')
    GROUP BY Tags.Id, Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(Votes.VoteTypeId = 2) AS UpVotesReceived,
        SUM(Votes.VoteTypeId = 3) AS DownVotesReceived,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore
    FROM Users
    LEFT JOIN Posts ON Posts.OwnerUserId = Users.Id
    LEFT JOIN Votes ON Votes.UserId = Users.Id AND Votes.PostId IN (SELECT Id FROM Posts)
    GROUP BY Users.Id, Users.DisplayName
),
PostHistories AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN PostHistoryTypeId = 4 THEN 1 END) AS TitleEdits,
        COUNT(CASE WHEN PostHistoryTypeId = 5 THEN 1 END) AS BodyEdits,
        COUNT(CASE WHEN PostHistoryTypeId = 6 THEN 1 END) AS TagEdits
    FROM PostHistory
    GROUP BY PostId
)

SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.AverageScore,
    U.DisplayName AS TopUser,
    U.TotalScore,
    U.UpVotesReceived,
    U.DownVotesReceived,
    PH.EditCount,
    PH.TitleEdits,
    PH.BodyEdits,
    PH.TagEdits
FROM TagStatistics T
JOIN UserReputation U ON U.UpVotesReceived = (
    SELECT MAX(UpVotesReceived) 
    FROM UserReputation
)
JOIN PostHistories PH ON PH.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%<', T.TagName, '>%)')
WHERE T.PostCount > 0
ORDER BY T.PostCount DESC, T.AverageScore DESC;
