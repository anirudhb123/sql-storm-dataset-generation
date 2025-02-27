WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(c.Id), 0) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title
),
Summary AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        p.Title,
        p.ViewCount,
        p.Score,
        ec.CommentCount,
        ec.LastCommentDate,
        ue.TotalBounty,
        ue.TotalComments,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation' 
            WHEN u.Reputation > 100 THEN 'Medium Reputation' 
            ELSE 'Low Reputation' 
        END AS ReputationCategory
    FROM 
        UserEngagement ue
    JOIN 
        PostsWithComments ec ON ue.UserId = ec.PostId
    JOIN 
        RankedPosts p ON ue.UserId = p.Id
    JOIN 
        Users u ON u.Id = ue.UserId
)
SELECT 
    ReputationCategory,
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    COUNT(DISTINCT UserId) AS UserCount
FROM 
    Summary
GROUP BY 
    ReputationCategory
ORDER BY 
    ReputationCategory DESC;
