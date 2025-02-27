WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 3
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
SelectedBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId, b.Name
),
RecentPostUpdates AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or reopened posts
    AND 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
),
FinalResults AS (
    SELECT 
        up.PostId,
        up.Title,
        rb.OwnerUserId,
        rb.CommentCount,
        rb.ViewCount,
        rb.Score,
        COALESCE(sb.BadgeCount, 0) AS GoldBadgeCount,
        COALESCE(rp.CloseReason, 'No recent closure action.') AS RecentCloseReason,
        CASE 
            WHEN rb.DownVoteCount > 2 THEN 'Highly Disliked' 
            ELSE 'Acceptable' 
        END AS PostRating
    FROM 
        RankedPosts rb
    LEFT JOIN 
        SelectedBadges sb ON sb.UserId = rb.OwnerUserId
    LEFT JOIN 
        RecentPostUpdates rp ON rb.PostId = rp.PostId
    WHERE 
        rb.rn = 1
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.CommentCount,
    fr.Score,
    fr.GoldBadgeCount,
    fr.RecentCloseReason,
    fr.PostRating
FROM 
    FinalResults fr
WHERE 
    fr.Score >= (SELECT AVG(Score) FROM Posts) -- Above average posts
OR 
    fr.GoldBadgeCount > 0 -- Users with Gold badges
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
