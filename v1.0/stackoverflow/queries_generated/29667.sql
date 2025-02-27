WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
HighReputationUsers AS (
    SELECT 
        UserId, 
        Reputation, 
        DisplayName, 
        PostsCount, 
        CommentsCount,
        GoldBadges, 
        SilverBadges, 
        BronzeBadges
    FROM 
        UserStats
    WHERE 
        Reputation > (SELECT AVG(Reputation) FROM Users)
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS PostTags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.PostsCount,
    u.CommentsCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    p.Title AS TopPostTitle,
    p.ViewCount AS TopPostViews,
    p.Score AS TopPostScore,
    p.PostTags
FROM 
    HighReputationUsers u
CROSS JOIN 
    TopPosts p
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC;
