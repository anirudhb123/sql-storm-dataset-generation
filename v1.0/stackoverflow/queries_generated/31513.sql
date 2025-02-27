WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass -- Gold > Silver > Bronze
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryAnalytics AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Only closed, reopened, and deleted
    GROUP BY 
        ph.PostId, p.Title, ph.PostHistoryTypeId, ph.CreationDate
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    up.BadgeCount,
    up.HighestBadgeClass,
    rp.Title AS TopQuestionTitle,
    rp.CreationDate AS TopQuestionDate,
    rp.Score AS TopQuestionScore,
    rp.ViewCount AS TopQuestionViewCount,
    pha.Title AS PostTitle,
    pha.HistoryCount,
    rp.TotalUpVotes,
    rp.TotalDownVotes
FROM 
    UserBadges up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.Rank = 1 -- Get top-ranked question for each user
LEFT JOIN 
    PostHistoryAnalytics pha ON rp.Id = pha.PostId
WHERE 
    up.BadgeCount > 0 -- Only users with badges
ORDER BY 
    up.BadgeCount DESC, rp.ViewCount DESC;
