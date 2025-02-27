WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND p.PostTypeId = 1  -- Considering only questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        COUNT(b.Id) AS BadgesCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges only
    GROUP BY 
        u.Id
),
UserWithRecentPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.UpvotesReceived,
        ua.DownvotesReceived,
        ua.BadgesCount,
        ua.LastBadgeDate,
        rp.Title AS RecentPostTitle,
        rp.ViewCount AS RecentPostViews,
        rp.Score AS RecentPostScore
    FROM 
        UserActivity ua
    LEFT JOIN 
        RankedPosts rp ON ua.UserId = rp.OwnerUserId
    WHERE 
        rp.RecentPostRank = 1  -- Only select the most recent post per user
)
SELECT 
    uwrp.*,
    CASE 
        WHEN uwrp.QuestionCount > 0 THEN 'Active'
        WHEN uwrp.UpvotesReceived > uwrp.DownvotesReceived THEN 'Positive Impact'
        ELSE 'Less Active'
    END AS UserStatus,
    COALESCE(uwrp.RecentPostTitle, 'No recent post') AS RecentPostTitle,
    COALESCE(uwrp.RecentPostViews, 0) AS RecentPostViews,
    COALESCE(uwrp.RecentPostScore, 0) AS RecentPostScore,
    CASE 
        WHEN uwrp.LastBadgeDate IS NOT NULL AND uwrp.LastBadgeDate > CURRENT_DATE - INTERVAL '1 year' 
        THEN 'Recently Awarded Badge' 
        ELSE 'No Recent Badge' 
    END AS BadgeStatus
FROM 
    UserWithRecentPosts uwrp
ORDER BY 
    uwrp.UpvotesReceived DESC NULLS LAST, 
    uwrp.QuestionCount DESC NULLS LAST;
