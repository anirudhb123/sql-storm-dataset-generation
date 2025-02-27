WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (
            SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
        ) AS t ON TRUE
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(v.CreationDate IS NOT NULL) AS TotalVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 -- Users with a decent reputation
    GROUP BY 
        u.Id
    ORDER BY 
        TotalScore DESC
    LIMIT 5
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    tu.TotalBounties,
    tu.TotalVotes
FROM 
    PostStatistics ps
JOIN 
    TopUsers tu ON ps.RecentPostRank = 1 -- Get the most recent post by each top user
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 10;
