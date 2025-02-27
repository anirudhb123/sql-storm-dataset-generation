
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts AS p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT cm.Id) AS CommentsMade,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users AS u
    LEFT JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments AS cm ON u.Id = cm.UserId
    LEFT JOIN 
        Votes AS v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.DisplayName,
    mp.Title,
    mp.ViewCount,
    mp.Score,
    mp.RankScore,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.TotalBounty,
    CASE 
        WHEN ua.PostsCreated IS NULL THEN 'No posts'
        ELSE 'Active User'
    END AS UserStatus
FROM 
    RankedPosts AS mp
JOIN 
    UserActivity AS ua ON mp.PostId = ua.UserId
WHERE 
    mp.RankScore <= 5
ORDER BY 
    mp.Score DESC, ua.TotalBounty DESC;
