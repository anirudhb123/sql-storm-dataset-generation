WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
HighActivityUsers AS (
    SELECT 
        ua.UserId,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBounties,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY ua.TotalComments DESC) AS CommentRank,
        RANK() OVER (ORDER BY ua.TotalBounties DESC) AS BountyRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 10 OR ua.TotalComments > 5
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COALESCE(hau.TotalPosts, 0) AS TotalPosts,
    COALESCE(hau.TotalComments, 0) AS TotalComments,
    COALESCE(hau.TotalBounties, 0) AS TotalBounties,
    CASE 
        WHEN hau.PostRank IS NOT NULL THEN 'P'
        ELSE 'N'
    END AS PostRankType,
    CASE 
        WHEN hau.CommentRank IS NOT NULL THEN 'C'
        ELSE 'N'
    END AS CommentRankType,
    CASE 
        WHEN hau.BountyRank IS NOT NULL THEN 'B'
        ELSE 'N'
    END AS BountyRankType,
    (SELECT COUNT(*) 
     FROM RecursivePostCTE r 
     WHERE r.OwnerUserId = u.Id) AS TotalSubPosts
FROM 
    Users u
LEFT JOIN 
    HighActivityUsers hau ON u.Id = hau.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC;
