WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(bp.Reputation) AS TotalReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
),
AggregatedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        us.DisplayName AS PostOwner,
        us.TotalScore,
        us.TotalViews,
        us.TotalReputation
    FROM 
        RankedPosts rp
    JOIN 
        UserScores us ON rp.OwnerUserId = us.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    PostOwner,
    TotalScore,
    TotalViews,
    TotalReputation
FROM 
    AggregatedResults
WHERE 
    UserPostRank = 1
ORDER BY 
    TotalScore DESC, 
    CreationDate DESC
LIMIT 10;
