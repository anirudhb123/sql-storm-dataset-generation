
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId,
        COALESCE(u.Reputation, 0) AS UserReputation,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', n.n), '><', -1) AS TagName
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
               UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.OwnerUserId, u.Reputation
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        u.DisplayName AS UserDisplayName,
        GROUP_CONCAT(ph.Comment SEPARATOR ' | ') AS HistoryComments
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, u.DisplayName
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.UserReputation,
    COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN rp.AnswerCount > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS AnswerStatus,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 0 THEN 'Positive Score'
        WHEN rp.Score < 0 THEN 'Negative Score'
        ELSE 'Neutral Score'
    END AS ScoreStatus,
    ph.HistoryComments
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadgeCounts ubc ON rp.OwnerUserId = ubc.UserId
LEFT JOIN 
    PostHistories ph ON rp.Id = ph.PostId
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.ViewCount DESC,
    rp.CreationDate DESC
LIMIT 100;
