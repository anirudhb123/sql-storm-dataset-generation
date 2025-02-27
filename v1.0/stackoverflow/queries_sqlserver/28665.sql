
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE PostTypeId = 1  
    GROUP BY value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(*) AS QuestionAnswered,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId = 2  
    GROUP BY u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        P.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes P ON ph.PostHistoryTypeId = P.Id
    WHERE ph.CreationDate > DATEADD(DAY, -30, GETDATE()) 
)

SELECT 
    t.TagName,
    t.PostCount,
    u.UserName,
    u.QuestionAnswered,
    u.TotalScore,
    r.CreationDate,
    r.PostHistoryType
FROM TopTags t
JOIN TopUsers u ON u.QuestionAnswered >= (SELECT MAX(PostCount) FROM TopTags)
JOIN RecentPostHistory r ON r.PostId IN (
    SELECT Id FROM Posts WHERE Tags LIKE '%' + t.TagName + '%'
)
ORDER BY t.PostCount DESC, u.TotalScore DESC;
