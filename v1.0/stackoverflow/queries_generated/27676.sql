WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),

TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        SUM(CASE WHEN rp.PostRank = 1 THEN 1 ELSE 0 END) AS TopPostCount,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        TotalComments > 0
)

SELECT 
    tu.DisplayName,
    tu.TopPostCount,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.TopPostCount >= 10 THEN 'Influencer'
        WHEN tu.TopPostCount BETWEEN 5 AND 9 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers tu
ORDER BY 
    tu.TotalUpVotes DESC, tu.TotalComments DESC
LIMIT 20;
