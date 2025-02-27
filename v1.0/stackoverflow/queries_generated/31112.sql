WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation >= 1000 -- Only consider users with reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBounties,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    tu.DisplayName AS TopUserDisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBounties,
    rp.Tags
FROM 
    RankedPosts rp
INNER JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    tu.UserRank <= 10
    AND rp.Rank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

This SQL query uses CTEs to rank posts and filter users based on their activities, including their total posts, comments, and bounties. It incorporates outer joins, window functions for ranking, string aggregation for tags, and sophisticated filtering and ordering logic.
