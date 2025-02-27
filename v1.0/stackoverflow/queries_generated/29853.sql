WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
BadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.TotalViews,
    ts.AverageScore,
    bs.BadgeCount,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges,
    phs.LastEditedDate,
    phs.CloseReason
FROM 
    TagStats ts
LEFT JOIN 
    BadgeStats bs ON bs.UserId = (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%' LIMIT 1)
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
ORDER BY 
    ts.PostCount DESC, ts.AverageScore DESC;
