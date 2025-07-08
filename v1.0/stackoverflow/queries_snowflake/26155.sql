
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
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsList,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS t
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score, 
        u.DisplayName, u.Reputation, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
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
