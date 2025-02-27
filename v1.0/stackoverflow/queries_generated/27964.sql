WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        TAGS.TagArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TAGS(TagArray)
    WHERE 
        p.PostTypeId = 1  -- Only questions
),

TopUsers AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class = 1, 0)::int) AS GoldBadges,
        SUM(COALESCE(b.Class = 2, 0)::int) AS SilverBadges,
        SUM(COALESCE(b.Class = 3, 0)::int) AS BronzeBadges
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Only questions
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 0 
    ORDER BY 
        Reputation DESC
    LIMIT 10
)

SELECT 
    ru.DisplayName AS UserName,
    ru.Reputation,
    rp.Title AS PopularPost,
    rp.ViewCount,
    rp.CreationDate,
    rp.TagArray
FROM 
    RankedPosts rp
JOIN 
    TopUsers ru ON rp.PostID IN (
        SELECT 
            CommentedPost.PostId 
        FROM 
            Comments CommentedPost 
        WHERE 
            CommentedPost.UserId = ru.UserID
    )
WHERE 
    rp.ViewRank = 1
ORDER BY 
    ru.Reputation DESC, 
    rp.ViewCount DESC;
