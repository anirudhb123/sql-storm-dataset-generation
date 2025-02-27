
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.OwnerUserId  -- Added to GROUP BY
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT TagName FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score, 
        u.DisplayName, u.Reputation, p.OwnerUserId  -- Updated GROUP BY clause
),
UserBadges AS (
    SELECT 
        b.UserId,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.Score,
    pm.UpVotes,
    pm.DownVotes,
    pm.TagsList,
    pm.OwnerDisplayName,
    pm.OwnerReputation,
    ub.BadgeNames,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    PostMetrics pm
LEFT JOIN 
    UserBadges ub ON pm.OwnerUserId = ub.UserId
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC
LIMIT 100;
