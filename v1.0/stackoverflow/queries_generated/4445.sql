WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalUpVotes,
        TotalDownVotes,
        CommentCount,
        RANK() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalViews,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.CommentCount
FROM 
    TopUsers u
WHERE 
    u.UserRank <= 10
UNION ALL
SELECT 
    NULL AS UserId,
    'Average' AS DisplayName,
    AVG(PostCount) AS PostCount,
    AVG(TotalViews) AS TotalViews,
    AVG(TotalUpVotes) AS TotalUpVotes,
    AVG(TotalDownVotes) AS TotalDownVotes,
    AVG(CommentCount) AS CommentCount
FROM 
    TopUsers
HAVING 
    COUNT(UserId) > 0
ORDER BY 
    UserRank NULLS FIRST;
