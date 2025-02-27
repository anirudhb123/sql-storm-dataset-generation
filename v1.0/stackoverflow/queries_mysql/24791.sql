
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN Votes v ON p.Id = v.PostId 
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.UpVotes,
        ua.DownVotes,
        ua.PostCount,
        ua.TotalViews,
        ua.AvgScore,
        @rank := IF(ua.UpVotes - ua.DownVotes > 0, 1, IF(ua.UpVotes - ua.DownVotes < 0, -1, 0)) AS RankGroup
    FROM UserActivity ua
    JOIN (SELECT @rank := 0) r
    ORDER BY ua.Reputation DESC
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC, SUM(COALESCE(p.ViewCount, 0)) DESC) AS TagRank
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(CASE WHEN ph.CreationDate > (NOW() - INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS RecentlyEdited
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    tu.DisplayName AS User,
    tu.Reputation,
    tu.PostCount,
    tu.TotalViews,
    tu.AvgScore,
    pt.TagName,
    pt.PostCount AS TagPostCount,
    pt.TotalViews AS TagTotalViews,
    re.EditCount,
    CASE 
        WHEN re.RecentlyEdited = 1 THEN 'Yes'
        ELSE 'No'
    END AS RecentlyEdited
FROM TopUsers tu
JOIN PopularTags pt ON pt.TagRank <= 10 
LEFT JOIN RecentEdits re ON re.PostId IN (
    SELECT p.Id 
    FROM Posts p 
    WHERE p.OwnerUserId = tu.UserId 
    AND p.CreationDate > (NOW() - INTERVAL 365 DAY)
)
WHERE tu.RankGroup <= 5
ORDER BY tu.Reputation DESC, pt.PostCount DESC;
