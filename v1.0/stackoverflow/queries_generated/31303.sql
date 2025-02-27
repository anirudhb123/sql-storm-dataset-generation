WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.Score > 0
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
PostWithEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ue.UserId,
        ue.VoteCount,
        ue.BadgeCount,
        ue.TotalCommentScore
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserEngagement ue ON ue.UserId = rp.PostId
)
SELECT 
    pwe.PostId,
    pwe.Title,
    pwe.VoteCount,
    pwe.BadgeCount,
    pwe.TotalCommentScore,
    COALESCE(CAST(ROUND((pwe.TotalCommentScore * 1.0 / NULLIF(pwe.VoteCount, 0)), 2) AS VARCHAR), 'N/A') AS CommentScorePerVote,
    CASE 
        WHEN pwe.BadgeCount > 5 THEN 'Active Contributor'
        WHEN pwe.BadgeCount BETWEEN 1 AND 5 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    PostWithEngagement pwe
ORDER BY 
    pwe.VoteCount DESC, pwe.BadgeCount DESC;
