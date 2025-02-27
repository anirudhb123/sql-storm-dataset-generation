WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    ru.DisplayName AS TopUser,
    rp.Title AS PostTitle,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(e.EditCount, 0) AS EditCount,
    tu.TotalViewCount,
    tu.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    TopUsers ru ON rp.PostId = ru.UserId
LEFT JOIN 
    PostHistoryCounts e ON rp.PostId = e.PostId
WHERE 
    rp.RankByUser = 1
ORDER BY 
    rp.Score DESC, 
    ru.TotalViewCount DESC
LIMIT 10;

WITH RECURSIVE RelatedQuestions AS (
    SELECT 
        pl.RelatedPostId,
        1 AS Level
    FROM 
        PostLinks pl
    WHERE 
        pl.PostId = <some_specific_post_id> -- Replace with an actual PostId

    UNION ALL

    SELECT 
        pl.RelatedPostId,
        rq.Level + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RelatedQuestions rq ON pl.PostId = rq.RelatedPostId
)
SELECT 
    DISTINCT p.Title
FROM 
    Posts p
INNER JOIN 
    RelatedQuestions rq ON p.Id = rq.RelatedPostId
WHERE 
    rq.Level <= 3; 
