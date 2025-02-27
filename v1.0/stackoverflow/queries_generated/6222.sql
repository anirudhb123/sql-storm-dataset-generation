WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, ph.Comment
),
RankedPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.Score,
        pa.ViewCount,
        pa.LastActivityDate,
        RANK() OVER (ORDER BY pa.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY pa.ViewCount DESC) AS ViewRank
    FROM 
        PostActivity pa
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.TotalUpvotes,
    us.TotalDownvotes,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViewCount,
    rp.LastActivityDate,
    rp.ScoreRank,
    rp.ViewRank
FROM 
    UserStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    RankedPosts rp ON p.Id = rp.PostId
ORDER BY 
    us.Reputation DESC, rp.Score DESC;
