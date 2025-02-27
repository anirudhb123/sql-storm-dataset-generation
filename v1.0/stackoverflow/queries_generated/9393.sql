WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.ViewCount > 1000
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        p.Title AS PostTitle,
        ph.UserDisplayName AS EditorDisplayName,
        ph.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    ub.UserId,
    ub.DisplayName AS UserDisplayName,
    ub.BadgeCount,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.Score AS PostScore,
    re.PostTitle AS RecentlyEditedPostTitle,
    re.EditorDisplayName AS LastEditor,
    re.EditDate AS LastEditDate
FROM UserBadges ub
JOIN PopularPosts pp ON ub.BadgeCount > 5
LEFT JOIN RecentEdits re ON pp.PostId = re.PostId AND re.EditRank = 1
WHERE ub.GoldBadges > 0
ORDER BY ub.BadgeCount DESC, pp.ViewCount DESC;
