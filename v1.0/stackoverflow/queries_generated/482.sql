WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.TotalPosts,
        us.TotalBounties,
        us.NetVotes,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS PostRank
    FROM 
        UserStatistics us
    WHERE 
        us.TotalPosts > 0
) 
SELECT 
    up.UserId,
    u.DisplayName,
    up.TotalPosts,
    up.TotalBounties,
    up.NetVotes,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    CASE 
        WHEN rp.AcceptedAnswer > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    ROW_NUMBER() OVER (PARTITION BY up.UserId ORDER BY rp.CreationDate DESC) AS RecentPostRank
FROM 
    TopUsers up
JOIN 
    Users u ON up.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    up.PostRank <= 10
ORDER BY 
    up.TotalPosts DESC,
    rp.CreationDate DESC NULLS LAST;
