WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostScoreAggregates AS (
    SELECT 
        p.Id AS PostId,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(COALESCE(c.Score, 0)) AS AverageCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
LatestPostUpdates AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        p.Title,
        p.Body
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate = (
            SELECT 
                MAX(CreationDate) 
            FROM 
                PostHistory 
            WHERE 
                PostId = p.Id
        )
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    p.PostId,
    p.Title,
    pa.TotalBounty,
    pa.AverageCommentScore,
    pa.UpVotes,
    pa.DownVotes,
    (SELECT COUNT(*) FROM Comments WHERE PostId = p.PostId) AS TotalComments,
    (SELECT COUNT(*) FROM RecursivePostHierarchy WHERE PostId = p.PostId) AS RelatedPostsLevelCount,
    ph.UserDisplayName AS LastUpdatedBy,
    ph.CreationDate AS LastUpdateDate
FROM 
    AggregatedUserStats u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
JOIN 
    PostScoreAggregates pa ON p.Id = pa.PostId
LEFT JOIN 
    LatestPostUpdates ph ON p.Id = ph.PostId
ORDER BY 
    u.Reputation DESC, 
    pa.TotalBounty DESC;
