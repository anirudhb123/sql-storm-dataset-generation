WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopAuthors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
        LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5 -- Users with more than 5 questions
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseActions,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteActions,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenActions
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ta.UserId,
    ta.DisplayName,
    ta.QuestionCount,
    ta.TotalScore,
    ta.GoldBadges,
    ta.SilverBadges,
    ta.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ph.CloseActions,
    ph.DeleteActions,
    ph.ReopenActions
FROM 
    TopAuthors ta
JOIN 
    RankedPosts rp ON ta.UserId = rp.OwnerUserId AND rp.Rank <= 3 -- Top 3 posts per user
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
ORDER BY 
    ta.TotalScore DESC, ta.QuestionCount DESC
LIMIT 100; -- Limit to top 100 results
