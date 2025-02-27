WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000 -- considering users with reputation above 1000
    GROUP BY u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM Posts p
    WHERE p.PostTypeId = 1 -- only questions
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.TotalViews,
    u.TotalScore,
    tt.Tag,
    ph.EditCount,
    ph.LastEditDate
FROM UserPostStats u
JOIN TopTags tt ON tt.Tag IN (SELECT UNNEST(string_to_array(u.Tags, '>')))
JOIN PostHistories ph ON ph.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
ORDER BY u.TotalScore DESC, u.TotalPosts DESC
LIMIT 50;
