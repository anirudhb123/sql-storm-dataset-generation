WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN h.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.VoteCount,
        ps.CommentCount,
        u.DisplayName AS UserDisplayName
    FROM 
        RecursivePostStats ps
    JOIN 
        Users u ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id) 
    WHERE 
        ps.Score > 0
    ORDER BY 
        ps.Score DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.VoteCount,
    tp.CommentCount,
    ubs.UserId,
    ubs.DisplayName AS OwnerDisplayName,
    ubs.BadgeCount,
    (SELECT COALESCE(AVG(ah.Score), 0) 
     FROM Posts ah
     WHERE ah.AcceptedAnswerId IN (SELECT Id FROM Posts WHERE ParentId = tp.PostId)) AS AvgAcceptedAnswerScore,
    tp.CloseCount
FROM 
    TopPosts tp
LEFT JOIN 
    UserBadgeStats ubs ON ubs.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CloseCount 
     FROM 
         PostHistory 
     WHERE 
         PostHistoryTypeId = 10 
     GROUP BY 
         PostId) h ON h.PostId = tp.PostId
ORDER BY 
    tp.Score DESC;
