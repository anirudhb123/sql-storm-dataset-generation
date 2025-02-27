WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        pl.LinkTypeId,
        1 AS Depth
    FROM 
        PostLinks pl
    WHERE 
        pl.LinkTypeId = 1 -- Starting with 'Linked'

    UNION ALL

    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        pl.LinkTypeId,
        rpl.Depth + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
    WHERE 
        pl.LinkTypeId = 1 AND rpl.Depth < 5 -- Limit depth to avoid infinite recursion
),
UserPostScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostScores
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        p.Title AS PostTitle,
        p.Score AS PostScore,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentUpdate
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month' 
),
FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(sp.RelatedPostId, -1) AS RelatedPostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostLinks sp ON p.Id = sp.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    f.Title AS PostTitle,
    f.ViewCount,
    f.CommentCount,
    rph.UserDisplayName AS RecentEditor,
    rph.CreationDate AS RecentEditDate,
    (CASE 
        WHEN f.RelatedPostId <> -1 THEN 'Linked'
        ELSE 'Standalone'
     END) AS PostStatus
FROM 
    TopUsers tu
JOIN 
    FilteredPosts f ON f.CommentCount > 5 -- More than 5 comments to qualify
LEFT JOIN 
    RecentPostHistory rph ON f.Id = rph.PostId AND rph.RecentUpdate = 1
WHERE 
    tu.ScoreRank <= 10 -- Top 10 users only
ORDER BY 
    tu.TotalScore DESC, f.ViewCount DESC;
