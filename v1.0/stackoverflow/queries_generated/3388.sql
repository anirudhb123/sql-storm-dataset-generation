WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100 -- Arbitrary reputation filter for active users
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts in the last year
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalBounty,
    p.Title AS PostTitle,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.PostRank
FROM 
    UserActivity u
LEFT JOIN 
    PostStats p ON u.UserId = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            ClosedDate IS NULL 
        ORDER BY 
            CreationDate DESC 
        OFFSET 0 ROWS 
        FETCH NEXT 1 ROWS ONLY
    )
WHERE 
    u.Ranking <= 10 -- Top 10 users by bounty
ORDER BY 
    u.TotalBounty DESC;
