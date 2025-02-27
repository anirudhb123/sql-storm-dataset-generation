WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.ViewCount
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' ELSE 'Open' END, ', ') AS Status,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 END) AS EditsCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopTags AS (
    SELECT 
        t.Id,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        Count(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    phs.Status,
    phs.EditsCount,
    phs.LastEditDate,
    rp.Rank,
    rp.AnswerCount,
    STRING_AGG(DISTINCT tt.TagName, ', ') AS TopTagsAggregate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
LEFT JOIN 
    UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
CROSS JOIN 
    TopTags tt
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, phs.Status, phs.EditsCount, phs.LastEditDate, rp.Rank, rp.AnswerCount, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
HAVING 
    SUM(rp.ViewCount) > 1000
ORDER BY 
    rp.ViewCount DESC NULLS LAST;
