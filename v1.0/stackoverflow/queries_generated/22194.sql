WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.RankByScore <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges bh ON bh.UserId = u.Id
    GROUP BY 
        u.Id
),
PostInteractions AS (
    SELECT 
        t.PostId,
        u.UserId,
        u.DisplayName,
        CASE 
            WHEN v.VoteTypeId IN (2, 5) THEN COUNT(v.Id) 
            ELSE 0 
        END AS Upvotes,
        CASE 
            WHEN v.VoteTypeId IN (3, 10) THEN COUNT(v.Id) 
            ELSE 0 
        END AS Downvotes
    FROM 
        TopPosts t
    JOIN 
        Votes v ON t.PostId = v.PostId
    JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        t.PostId, u.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostsCount,
    up.TotalBounty,
    up.BadgesCount,
    pi.PostId,
    pi.Upvotes,
    pi.Downvotes,
    CASE 
        WHEN pi.Upvotes > pi.Downvotes THEN 'Positive Interaction'
        WHEN pi.Upvotes < pi.Downvotes THEN 'Negative Interaction'
        ELSE 'Neutral Interaction'
    END AS InteractionType
FROM 
    UserActivity up
LEFT JOIN 
    PostInteractions pi ON up.UserId = pi.UserId
WHERE 
    up.PostsCount > 10
ORDER BY 
    up.TotalBounty DESC, up.PostsCount DESC, pi.Upvotes DESC;
