WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScores
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScores <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvotesReceived,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvotesReceived,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryWithComments AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserId, ph.Comment, p.Title
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        us.UserId,
        us.DisplayName,
        us.UpvotesReceived,
        us.DownvotesReceived,
        ph.CommentCount,
        ph.CreationDate AS LastHistoryUpdate
    FROM 
        TopPosts tp
    JOIN 
        Users us ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
    LEFT JOIN 
        PostHistoryWithComments ph ON tp.PostId = ph.PostId
    ORDER BY 
        tp.Score DESC, us.UpvotesReceived - us.DownvotesReceived DESC
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.DisplayName AS PostOwner,
    fr.UpvotesReceived,
    fr.DownvotesReceived,
    fr.CommentCount,
    fr.LastHistoryUpdate,
    CASE 
        WHEN fr.CommentCount = 0 THEN 'No comments'
        ELSE 'Comments available'
    END AS CommentStatus,
    CASE 
        WHEN fr.UpvotesReceived > 5 THEN 'Popular'
        WHEN fr.DownvotesReceived > 5 THEN 'Needs improvement'
        ELSE 'Moderate popularity'
    END AS PopularityStatus
FROM 
    FinalResults fr
WHERE 
    (fr.CommentStatus = 'No comments' OR fr.UpvotesReceived IS NOT NULL)
ORDER BY 
    fr.LastHistoryUpdate DESC, fr.Score DESC;

WITH Recursive BadgesCTE AS (
    SELECT 
        b.Id,
        b.UserId,
        b.Name,
        b.Class,
        1 AS RecursionDepth
    FROM 
        Badges b
    WHERE 
        b.Class = 1  -- Gold badges
    UNION ALL
    SELECT 
        b.Id,
        b.UserId,
        b.Name,
        b.Class,
        r.RecursionDepth + 1
    FROM 
        Badges b
    JOIN 
        BadgesCTE r ON b.UserId = r.UserId 
    WHERE 
        b.Class = 2  -- Silver badges
)
SELECT 
    UserId,
    COUNT(*) AS TotalBadgeDepth
FROM 
    BadgesCTE
GROUP BY 
    UserId
HAVING 
    COUNT(*) > 3;  -- Display users with more than 3 cumulative badges
