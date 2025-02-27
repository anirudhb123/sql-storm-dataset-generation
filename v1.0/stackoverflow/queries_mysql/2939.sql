
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY DATE_FORMAT(p.CreationDate, '%Y-%m') ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.Tags
),
HighScoringPosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM RankedPosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id AND b.Class = 1 
    WHERE rp.Rank <= 5
),
AnswerCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id
)
SELECT 
    hsp.*,
    ac.AnswerCount,
    CASE 
        WHEN hsp.ViewCount IS NULL THEN 'No Views'
        ELSE CONCAT(hsp.ViewCount, ' Views')
    END AS ViewCountDisplay
FROM HighScoringPosts hsp
LEFT JOIN AnswerCounts ac ON hsp.PostId = ac.PostId
ORDER BY hsp.Score DESC, hsp.CreationDate ASC;
