WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000  -- Starting point for notable users
    
    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN UserReputation ur ON u.Id = (SELECT TOP 1 p.OwnerUserId 
                                             FROM Posts p 
                                             WHERE p.OwnerUserId <> -1 
                                             AND p.Score > 0 
                                             AND p.OwnerUserId NOT IN (SELECT UserId FROM UserReputation)
                                             ORDER BY p.Score DESC)
    WHERE 
        ur.Level < 5  -- Level up to 5
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9)  -- Bounty start and close
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate AS PostCreationDate,
        pd.Score AS PostScore,
        pd.CommentCount,
        pd.TotalBounty
    FROM 
        Users u
    JOIN 
        PostDetail pd ON u.Id = pd.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COUNT(up.PostId) AS TotalPosts,
    SUM(up.PostScore) AS TotalScore,
    AVG(up.CommentCount) AS AvgComments,
    SUM(up.TotalBounty) AS TotalBountyAwards,
    ROW_NUMBER() OVER (PARTITION BY ur.Level ORDER BY SUM(up.PostScore) DESC) AS RankWithinLevel
FROM 
    UserPosts up
JOIN 
    UserReputation ur ON up.UserId = ur.UserId
GROUP BY 
    u.UserId, u.DisplayName, ur.Level
HAVING 
    COUNT(up.PostId) > 10  -- Only include users with more than 10 posts
ORDER BY 
    ur.Level, TotalScore DESC;
