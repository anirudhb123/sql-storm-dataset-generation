
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
        STRING_AGG(tag.TagName, ', ') WITHIN GROUP (ORDER BY tag.TagName) AS TagsList
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            p.Id AS pId,
            value AS TagName
        FROM Posts p
        CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    ) AS tag ON p.Id = tag.pId
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
