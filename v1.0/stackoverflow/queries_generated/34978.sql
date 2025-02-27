WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Close/Reopen'
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Delete/Undelete'
            ELSE 'Other'
        END AS HistoryTypeLabel,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS TotalHistoryEntries
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year' -- Filter recent history
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(up.BadgeCount, 0) AS TotalBadges,
        COALESCE(ph.TotalHistoryEntries, 0) AS TotalHistoryEntries,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts
    FROM 
        Users u
    LEFT JOIN 
        UserBadges up ON u.Id = up.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistoryDetail ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName, up.BadgeCount, ph.TotalHistoryEntries
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalBadges,
    ua.TotalPosts,
    ua.TotalHistoryEntries,
    ua.PositiveScorePosts,
    RANK() OVER (ORDER BY ua.TotalBadges DESC, ua.TotalPosts DESC) AS UserRank
FROM 
    UserActivity ua
ORDER BY 
    ua.UserRank;
