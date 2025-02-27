WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
), 

TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        PositivePostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserPostCounts
    WHERE PostCount > 0
),

RecentEdits AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostTypeName,
        DATEDIFF(CURRENT_TIMESTAMP, ph.CreationDate) AS DaysSinceEdit
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE ph.CreationDate >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 30 DAY)
)

SELECT 
    u.DisplayName,
    tc.PostCount,
    tc.PositivePostCount,
    COUNT(DISTINCT re.PostId) AS RecentEditsCount,
    COALESCE(SUM(CASE WHEN re.DaysSinceEdit <= 7 THEN 1 ELSE 0 END), 0) AS EditsLastWeek,
    STRING_AGG(DISTINCT CONCAT('Post ID: ', re.PostId, ' [', re.PostTypeName, ']')) AS RecentEditedPosts
FROM Users u
JOIN TopUsers tc ON u.Id = tc.UserId
LEFT JOIN RecentEdits re ON u.Id = re.UserId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName, tc.PostCount, tc.PositivePostCount
ORDER BY tc.PostCount DESC
LIMIT 10;
