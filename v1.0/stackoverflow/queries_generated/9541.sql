WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- only upvotes and downvotes
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN rc.CommentCount ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN rc.VoteCount ELSE 0 END) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rc ON u.Id = rc.PostId
    WHERE 
        u.Reputation > 100 -- filtering to display users with above 100 reputation
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    us.TotalViews,
    us.TotalComments,
    us.TotalVotes
FROM 
    UserStats us
ORDER BY 
    us.TotalScore DESC, us.TotalPosts DESC
LIMIT 10;
