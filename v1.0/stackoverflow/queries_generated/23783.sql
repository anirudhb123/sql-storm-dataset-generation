WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        CASE 
            WHEN p.LastActivityDate IS NULL THEN 'No Activity'
            ELSE 'Active'
        END AS ActivityStatus
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        RANK() OVER (ORDER BY (ue.TotalBounty + ue.TotalComments + ue.UpVotes - ue.DownVotes) DESC) AS UserRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.TotalBounty IS NOT NULL OR ue.TotalComments IS NOT NULL
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.ActivityStatus,
    tu.DisplayName AS TopUserDisplayName,
    tu.UserRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.PostRank = 1 -- Join with TopUsers to get the most active user for each post
WHERE 
    rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)  -- Only include posts above average view count
    AND rp.Score >= 10  -- Only include high-scoring posts
    AND rp.CreationDate >= '2023-01-01'  -- Filter for the current year
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC;
