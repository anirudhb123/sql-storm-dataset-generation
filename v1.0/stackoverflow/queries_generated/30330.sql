WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        Level + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE ur ON u.Reputation < ur.Reputation
    WHERE 
        ur.Level < 5
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COUNT(v.Id) AS VoteCount,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(ps.ViewCount) AS TotalPostViews,
        AVG(ps.AverageCommentScore) AS AvgCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id
),
FinalResults AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        ur.Reputation,
        tu.TotalBadges,
        tu.TotalPostViews,
        tu.AvgCommentScore
    FROM 
        TopUsers tu
    JOIN 
        UserReputationCTE ur ON tu.UserId = ur.UserId
)
SELECT 
    fr.DisplayName,
    fr.Reputation,
    fr.TotalBadges,
    fr.TotalPostViews,
    fr.AvgCommentScore
FROM 
    FinalResults fr
WHERE 
    fr.TotalBadges > 5 AND 
    fr.TotalPostViews > 1000
ORDER BY 
    fr.Reputation DESC;
