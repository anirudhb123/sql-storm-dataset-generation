WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class = 1, 0)::int) AS GoldBadges,
        SUM(COALESCE(b.Class = 2, 0)::int) AS SilverBadges,
        SUM(COALESCE(b.Class = 3, 0)::int) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 0
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN rp.Score < 0 THEN 'This post has negative score.'
        ELSE 'This post is well-received.'
    END AS PostFeedback,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Votes v 
            WHERE v.PostId = rp.Id 
            AND v.VoteTypeId = 2
        ) THEN 'Has Upvotes'
        ELSE 'No Upvotes'
    END AS VoteStatus
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.PostRank = 1
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.CreationDate DESC;
