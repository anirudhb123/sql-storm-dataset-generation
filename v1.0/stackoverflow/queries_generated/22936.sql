WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0 
    GROUP BY 
        u.Id
), ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        ur.DisplayName AS CloserDisplayName
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    LEFT JOIN 
        Users ur ON ph.UserId = ur.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions 
        AND ph.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
), UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(com.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Comments com ON u.Id = com.UserId 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id
)

SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.Rank,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(c.ClosedPostCount, 0) AS ClosedPostCount, 
    COALESCE(c.ClosedPostDetails, 'No closed posts') AS ClosedPostDetails,
    ua.CommentCount,
    ua.UpVoteCount,
    ua.DownVoteCount,
    ua.TotalViews
FROM 
    UserRankings ur
LEFT JOIN 
    (SELECT 
         uv.UserId, 
         COUNT(cp.PostId) AS ClosedPostCount,
         STRING_AGG(CONCAT_WS(' - ', cp.Title, cp.ClosedDate::text, cp.CloseReason, cp.CloserDisplayName), '; ') AS ClosedPostDetails
     FROM 
         ClosedPosts cp
     JOIN 
         Users uv ON cp.CloserDisplayName = uv.DisplayName
     GROUP BY 
         uv.UserId) c ON ur.UserId = c.UserId
LEFT JOIN 
    UserActivity ua ON ur.UserId = ua.UserId
WHERE 
    ur.BadgeCount > 5
ORDER BY 
    ur.Reputation DESC, ur.Rank, ua.TotalViews DESC;
