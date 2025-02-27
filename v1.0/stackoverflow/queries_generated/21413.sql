WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.OwnerUserId,
        pd.Score,
        pd.CommentCount,
        pd.RelatedPosts,
        RANK() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.Score DESC, pd.CommentCount DESC) AS PostRank
    FROM 
        PostDetails pd
),
TagsCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    GROUP BY 
        t.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Score,
    rp.CommentCount,
    rp.RelatedPosts,
    tc.TagName,
    tc.PostCount
FROM 
    Users u
INNER JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    TagsCount tc ON tc.PostCount > 100  -- Tags that have more than 100 posts
WHERE 
    (u.Reputation > 500 OR rp.Score IS NOT NULL)  -- Users with high reputation or having active posts
ORDER BY 
    u.Reputation DESC, rp.Score DESC NULLS LAST
LIMIT 100;

