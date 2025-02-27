WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank,
        COUNT(com.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS MostRecentCloseDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        r.*,
        CASE 
            WHEN r.MostRecentCloseDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        RankedPosts r
),
BestPerformingPosts AS (
    SELECT 
        *,
        CASE
            WHEN CommentCount > 10 AND Score >= 10 THEN 'Highly Engaging'
            WHEN CommentCount <= 10 AND Score < 10 THEN 'Low Engagement'
            ELSE 'Moderate Engagement'
        END AS EngagementLevel
    FROM 
        ClosedPosts
    WHERE 
        ScoreRank <= 20
)
SELECT 
    b.Id AS BadgeId,
    b.Name AS BadgeName,
    COUNT(DISTINCT u.Id) AS BadgeHoldersCount,
    SUM(CASE 
        WHEN b.Class = 1 THEN 1 
        ELSE 0 END) AS GoldBadgeCount,
    SUM(CASE 
        WHEN b.Class = 2 THEN 1 
        ELSE 0 END) AS SilverBadgeCount,
    SUM(CASE 
        WHEN b.Class = 3 THEN 1 
        ELSE 0 END) AS BronzeBadgeCount,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', bp.Title, bp.EngagementLevel), '; ') AS EngagingPosts
FROM 
    Badges b
LEFT JOIN 
    Users u ON b.UserId = u.Id
LEFT JOIN 
    BestPerformingPosts bp ON u.Id = bp.OwnerUserId
WHERE 
    b.Date >= NOW() - INTERVAL '1 year' 
GROUP BY 
    b.Id, b.Name
HAVING 
    COUNT(DISTINCT u.Id) > 5 
ORDER BY 
    BadgeHoldersCount DESC, b.Name;

