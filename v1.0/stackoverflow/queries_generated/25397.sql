WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TagsExtracted AS (
    SELECT 
        PostId,
        UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CommentCount,
    rp.UpVotes,
    tg.Tag,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    TagsExtracted tg ON rp.PostId = tg.PostId
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.Rank = 1 AND 
    upVotes > 50
ORDER BY 
    rp.UpVotes DESC, 
    rp.CommentCount DESC;
