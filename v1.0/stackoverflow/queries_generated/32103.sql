WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopGoldBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS GoldBadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
),
UserEngagement AS (
    SELECT 
        u.UserId,
        COALESCE(gb.GoldBadgeCount, 0) AS GoldBadges,
        ups.TotalPosts,
        ups.TotalViews,
        ups.AverageScore,
        (CASE 
            WHEN ups.AverageScore IS NOT NULL AND ups.AverageScore >= 10 THEN 'High Engagement'
            WHEN ups.AverageScore IS NOT NULL AND ups.AverageScore BETWEEN 5 AND 10 THEN 'Medium Engagement'
            ELSE 'Low Engagement'
         END) AS EngagementLevel
    FROM 
        UserPostStats ups
    LEFT JOIN 
        TopGoldBadges gb ON ups.UserId = gb.UserId
),

RecentPostEditHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (24, 10)  -- Suggested Edit Applied or Post Closed
)

SELECT 
    ue.DisplayName AS UserName,
    ue.GoldBadges,
    ue.TotalPosts,
    ue.TotalViews,
    ue.AverageScore,
    ue.EngagementLevel,
    COALESCE(rpe.UserDisplayName, 'No edits') AS LastEditor,
    COALESCE(rpe.CreationDate, 'N/A') AS LastEditDate,
    COALESCE(rpe.Comment, 'N/A') AS LastEditComment
FROM 
    UserEngagement ue
LEFT JOIN 
    RecentPostEditHistory rpe ON ue.UserId = rpe.UserId
WHERE 
    ue.TotalPosts > 0
ORDER BY 
    ue.TotalViews DESC, 
    ue.AverageScore DESC;
