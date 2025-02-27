WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS RankByViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalViews,
        ua.UpVotes,
        ua.DownVotes,
        ua.RankByViews
    FROM UserActivity ua
    WHERE ua.PostCount > 10
),
TagAnalytics AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        SUM(pt.ViewCount) AS TotalViews,
        AVG(pt.Score) AS AvgPostScore
    FROM Tags t
    JOIN Posts pt ON pt.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserTagAssociations AS (
    SELECT
        u.Id AS UserId,
        t.Id AS TagId,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN Tags t ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY u.Id, t.Id
),
CombinedResults AS (
    SELECT 
        tu.DisplayName,
        tu.TotalViews,
        ta.TagName,
        ta.PostCount AS TagPostCount,
        ta.TotalViews AS TagTotalViews,
        ROW_NUMBER() OVER (PARTITION BY tu.UserId ORDER BY ta.PostCount DESC) AS TagRank
    FROM TopUsers tu
    LEFT JOIN TagAnalytics ta ON TRUE
)
SELECT 
    cr.DisplayName,
    cr.TagName,
    cr.TagPostCount,
    cr.TagTotalViews,
    cr.TotalViews AS UserTotalViews,
    cr.TagRank
FROM CombinedResults cr
WHERE cr.TagRank <= 3
ORDER BY cr.UserTotalViews DESC, cr.TagPostCount DESC;
