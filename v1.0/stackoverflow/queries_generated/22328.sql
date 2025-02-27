WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName) 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Only consider users with more than 5 posts
),
CloseReasonStats AS (
    SELECT 
        pr.PostId,
        string_agg(cr.Name, ', ') AS ReasonNames,
        COUNT(*) AS ReasonCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON (ph.Comment::int = cr.Id AND ph.PostHistoryTypeId = 10) 
    GROUP BY 
        pr.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ScoreRank,
    ua.DisplayName AS Creator,
    ua.PostsCreated,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    cs.ReasonNames,
    cs.ReasonCount,
    rp.Upvotes,
    rp.Downvotes,
    (rp.Upvotes - rp.Downvotes) AS NetVotes,
    COALESCE(rp.Tags, 'No Tags') AS PostTags
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    CloseReasonStats cs ON rp.PostId = cs.PostId
ORDER BY 
    rp.Score DESC NULLS LAST, 
    ua.PostsCreated DESC,
    cs.ReasonCount DESC;
