WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), '{}') AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Tags,
        u.DisplayName AS OwnerDisplayName,
        b.Name AS BadgeName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 -- Only Gold Badges
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.OwnerDisplayName,
    pwb.CommentCount,
    pwb.AnswerCount,
    pwb.Tags,
    COUNT(DISTINCT b.Id) AS GoldBadgeCount
FROM 
    PostWithBadges pwb
LEFT JOIN 
    Badges b ON pwb.OwnerDisplayName = u.DisplayName
GROUP BY 
    pwb.PostId, pwb.Title, pwb.OwnerDisplayName, pwb.CommentCount, pwb.AnswerCount, pwb.Tags
ORDER BY 
    GoldBadgeCount DESC, pwb.CommentCount DESC
LIMIT 10;
