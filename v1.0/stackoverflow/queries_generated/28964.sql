WITH user_details AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
top_users AS (
    SELECT 
        ud.UserId,
        ud.DisplayName,
        ud.Reputation,
        ud.TotalPosts,
        ud.TotalComments,
        (ud.GoldBadges + ud.SilverBadges + ud.BronzeBadges) AS TotalBadges
    FROM 
        user_details ud
    WHERE 
        ud.Reputation >= 1000
    ORDER BY 
        TotalBadges DESC, ud.Reputation DESC
    LIMIT 10
),
post_details AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON true
    LEFT JOIN 
        LATERAL (SELECT TagName FROM Tags WHERE Id = tag_array) t ON true
    WHERE 
        p.ViewCount > 50
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
user_post_interaction AS (
    SELECT 
        u.DisplayName,
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        p.VoteCount,
        c.CommentCount
    FROM 
        top_users u
    JOIN 
        post_details pp ON u.UserId = pp.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes v
        GROUP BY 
            PostId
    ) p ON pp.PostId = p.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON pp.PostId = c.PostId
)
SELECT 
    ui.DisplayName,
    ui.PostId,
    ui.Title,
    ui.CreationDate,
    COALESCE(ui.VoteCount, 0) AS VoteCount,
    COALESCE(ui.CommentCount, 0) AS CommentCount
FROM 
    user_post_interaction ui
ORDER BY 
    ui.VoteCount DESC, 
    ui.CommentCount DESC;
