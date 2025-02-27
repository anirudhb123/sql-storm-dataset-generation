WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.PostTypeId, 
        p.OwnerUserId, 
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.OwnerUserId, p.CreationDate
),
UserBadges AS (
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
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerUserId,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        rp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS TopRank
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank = 1 -- Only the top-ranked posts per user
)
SELECT 
    p.Title, 
    u.DisplayName, 
    u.Reputation,
    COALESCE(tp.GoldBadges, 0) AS GoldBadges,
    COALESCE(tp.SilverBadges, 0) AS SilverBadges,
    COALESCE(tp.BronzeBadges, 0) AS BronzeBadges,
    tp.CommentCount
FROM 
    TopPosts tp 
JOIN 
    Users u ON tp.OwnerUserId = u.Id
JOIN 
    Posts p ON tp.PostId = p.Id
WHERE 
    u.Reputation > 500 -- Only consider users with a reputation greater than 500
ORDER BY 
    tp.CommentCount DESC, 
    u.Reputation DESC
OPTION (RECOMPILE); -- Consider recompiling for fresh execution plan

-- Optionally, include an outer join with PostHistory to see if any modifications were applied to the posts
LEFT JOIN (
    SELECT 
        ph.PostId,
        COUNT(*) AS ModificationCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tags modified
    GROUP BY 
        ph.PostId
) ph ON p.Id = ph.PostId;
This SQL query provides a detailed analysis of posts created within the last year, highlighting the relationship between user reputation, comment counts, and badge achievements, while efficiently utilizing subqueries, CTEs, window functions, and conditional aggregations. The results are ordered to focus on the most engaged posts.
