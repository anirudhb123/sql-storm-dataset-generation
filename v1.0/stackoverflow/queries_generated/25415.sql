WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TagPostCounts AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY Tag
),
PostHistoryCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13)) AS ClosureActions
    FROM PostHistory ph
    GROUP BY ph.UserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalComments,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COALESCE(tpc.PostCount, 0) AS TotalTagsHandled,
        COALESCE(phc.ClosureActions, 0) AS TotalClosureActions
    FROM UserStats us
    LEFT JOIN TagPostCounts tpc ON INSTR(us.DisplayName, tpc.Tag) > 0
    LEFT JOIN PostHistoryCounts phc ON us.UserId = phc.UserId
)
SELECT 
    fs.DisplayName,
    fs.Reputation,
    fs.TotalPosts,
    fs.TotalComments,
    fs.GoldBadges,
    fs.SilverBadges,
    fs.BronzeBadges,
    fs.TotalTagsHandled,
    fs.TotalClosureActions,
    RANK() OVER (ORDER BY fs.Reputation DESC) AS ReputationRank
FROM FinalStats fs
ORDER BY fs.Reputation DESC, fs.TotalPosts DESC
LIMIT 10;
