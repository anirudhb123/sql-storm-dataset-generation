
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryClosed AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 n FROM 
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1 
    WHERE 
        PostTypeId = 1
),
TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    up.UserId,
    up.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title AS TopPostTitle,
    rp.ViewCount AS TopPostViews,
    rp.Score AS TopPostScore,
    COALESCE(phc.CloseVotes, 0) AS TotalCloseVotes,
    tc.TagName,
    tc.PostCount
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostHistoryClosed phc ON rp.PostId = phc.PostId
LEFT JOIN 
    TagCounts tc ON FIND_IN_SET(tc.TagName, (SELECT GROUP_CONCAT(Tag) FROM PopularTags)) > 0
WHERE 
    up.Reputation > 1000
    AND rp.rn = 1
    AND (rp.ViewCount IS NOT NULL OR rp.Score < 0)
ORDER BY 
    up.Reputation DESC,
    rp.ViewCount DESC
LIMIT 10;
