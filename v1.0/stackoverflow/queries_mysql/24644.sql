
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(c.Text SEPARATOR '; ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 
                CONCAT('Closed on ', ph.CreationDate)
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 
                CONCAT('Deleted on ', ph.CreationDate)
            ELSE 
                CONCAT('Edited on ', ph.CreationDate)
        END AS HistoryText
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURDATE() - INTERVAL 6 MONTH
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS AwardedBadges
    FROM 
        Badges b
    WHERE 
        b.Date >= CURDATE() - INTERVAL 2 YEAR
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.Comments, 'No Comments') AS Comments,
    COALESCE(pdh.HistoryText, 'No History') AS PostHistory,
    ub.BadgeCount,
    ub.AwardedBadges,
    CASE 
        WHEN rp.Score > 0 THEN 
            'Positive Score'
        WHEN rp.Score < 0 THEN 
            'Negative Score'
        ELSE 
            'Neutral'
    END AS ScoreDescription
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryDetails pdh ON rp.PostId = pdh.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.rn = 1
  AND 
    (rp.AnswerCount > 0 OR u.Reputation > 1000)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
