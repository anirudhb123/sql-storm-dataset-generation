WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (PARTITION BY ps.Score ORDER BY ps.CommentCount DESC) AS ScoreRank
    FROM 
        PostStats ps
)
SELECT 
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.TotalBadges,
    ue.TotalBounty,
    rp.Title,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.ScoreRank
FROM 
    UserEngagement ue
INNER JOIN 
    RankedPosts rp ON ue.UserId = rp.PostId
WHERE 
    (ue.TotalPosts > 0 AND ue.TotalComments > 0)
    OR (ue.TotalBounty IS NOT NULL AND ue.TotalBounty > 0)
ORDER BY 
    ue.TotalPosts DESC,
    rp.ScoreRank
LIMIT 100;
