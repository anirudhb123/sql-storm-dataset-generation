WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalBounty,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, UpVotes DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalBounty,
    tu.UpVotes,
    tu.DownVotes,
    COALESCE(t.Tags, 0) AS TotalTags
FROM 
    TopUsers tu
LEFT JOIN 
    (SELECT 
         OwnerUserId, 
         COUNT(DISTINCT Tags) AS Tags 
     FROM 
         Posts 
     CROSS APPLY 
         STRING_SPLIT(Tags, ',') 
     GROUP BY 
         OwnerUserId) t ON tu.UserId = t.OwnerUserId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
