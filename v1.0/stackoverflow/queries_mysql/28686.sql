
WITH UserRanks AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY COUNT(b.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBadges,
        GoldBadges,
        SilverBadges,
        BronzeBadges
    FROM UserRanks
    WHERE UserRank <= 10
),
PostMetadata AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(tag.TagName SEPARATOR ', ') AS TagsList
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) 
        -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS tag ON p.Id = tag.PostId
    GROUP BY p.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.CreationDate,
        pm.ViewCount,
        pm.Score,
        pm.OwnerDisplayName,
        pm.TagsList,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount
    FROM PostMetadata pm
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS RevisionCount
        FROM PostHistory
        GROUP BY PostId
    ) ph ON pm.PostId = ph.PostId
    WHERE pm.Score > 0 
    AND pm.ViewCount > 100
)
SELECT 
    tu.DisplayName,
    tu.TotalBadges,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagsList,
    pd.RevisionCount
FROM TopUsers tu
JOIN PostDetails pd ON pd.OwnerDisplayName = tu.DisplayName
ORDER BY tu.TotalBadges DESC, pd.Score DESC;
