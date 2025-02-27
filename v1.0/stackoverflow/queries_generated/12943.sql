-- Performance benchmarking query to analyze popular posts, user engagement, and post history changes

WITH PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
    ORDER BY 
        p.Score DESC
    LIMIT 10
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostsCount DESC
    LIMIT 5
),

PostHistoryChanges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS ChangeCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, ph.PostHistoryTypeId
)

SELECT 
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    pp.VoteCount,
    ue.UserId,
    ue.DisplayName AS TopUser,
    ue.PostsCount,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges,
    phc.PostHistoryTypeId,
    phc.ChangeCount
FROM 
    PopularPosts pp
CROSS JOIN 
    UserEngagement ue
LEFT JOIN 
    PostHistoryChanges phc ON pp.PostId = phc.PostId
ORDER BY 
    pp.Score DESC, ue.PostsCount DESC;
