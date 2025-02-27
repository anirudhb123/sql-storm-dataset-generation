
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
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
        value AS Tag
    FROM 
        STRING_SPLIT((SELECT STRING_AGG(Tags, '><') FROM Posts WHERE PostTypeId = 1), '><')
),
TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
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
    TagCounts tc ON tc.TagName IN (SELECT Tag FROM PopularTags)
WHERE 
    up.Reputation > 1000
    AND rp.rn = 1
    AND (rp.ViewCount IS NOT NULL OR rp.Score < 0)
ORDER BY 
    up.Reputation DESC,
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
