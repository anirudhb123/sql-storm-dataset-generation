WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
TopRatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        pt.Name AS PostType,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CreationDate, pt.Name
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.ViewCount,
    trp.TotalBounty,
    trp.CommentCount,
    ue.UserId,
    ue.DisplayName,
    ue.PostsCreated,
    ue.TotalCommentScore,
    ue.TotalBadgeClass
FROM 
    TopRatedPosts trp
JOIN 
    Users ue ON trp.PostId = (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = ue.UserId 
        ORDER BY p.CreationDate DESC 
        LIMIT 1
    )
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
