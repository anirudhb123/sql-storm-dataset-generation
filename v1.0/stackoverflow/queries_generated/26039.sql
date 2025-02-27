WITH RankedTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM Tags t
    LEFT JOIN Posts p ON t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
    GROUP BY t.TagName
), FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 1000
), TagStatistics AS (
    SELECT
        tt.TagName,
        MAX(u.UserName) AS TopUserName,
        COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners,
        AVG(u.Reputation) AS AvgOwnerReputation
    FROM RankedTags tt
    JOIN Posts p ON tt.TagName = ANY (string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE tt.PostCount > 5
    GROUP BY tt.TagName
)
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    u.DisplayName AS TopUser,
    u.Reputation AS TopUserReputation,
    ts.UniquePostOwners,
    ts.AvgOwnerReputation
FROM RankedTags t
JOIN FilteredUsers u ON t.TagRank = 1
JOIN TagStatistics ts ON ts.TagName = t.TagName
WHERE t.TagRank <= 10
ORDER BY t.PostCount DESC;
