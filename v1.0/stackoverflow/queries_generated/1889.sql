WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE( COUNT(c.Id), 0 ) AS CommentCount,
        COALESCE( SUM(v.VoteTypeId = 2), 0 ) AS UpVotes,
        COALESCE( SUM(v.VoteTypeId = 3), 0 ) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id 
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        COUNT(ps.PostId) AS TotalPosts,
        AVG(ps.ViewCount) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.PostId 
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        AverageViewCount,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS Rank
    FROM 
        UserPerformance
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalPosts,
    tu.AverageViewCount,
    (SELECT COUNT(DISTINCT p.Id) 
     FROM Posts p 
     WHERE p.OwnerUserId = tu.UserId AND p.ViewCount >= 1000) AS HighViewCountPosts,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
              FROM Posts p 
              JOIN LATERAL string_to_array(p.Tags, ',') AS tag ON true
              JOIN Tags t ON t.TagName = tag 
              WHERE p.OwnerUserId = tu.UserId), 'No Tags') AS AssociatedTags
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
