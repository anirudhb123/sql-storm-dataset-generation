WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ', ')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.OwnerDisplayName, p.OwnerUserId
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT r.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    up.DisplayName AS UserDisplayName,
    up.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.TagList
FROM 
    UserSummary up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per user
ORDER BY 
    up.Reputation DESC, rp.ViewCount DESC;
