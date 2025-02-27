-- Benchmarking query to analyze the distribution of post types, user activity, and vote statistics

-- 1. Count of posts by PostType
WITH PostTypeCount AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

-- 2. User activity: post count and reputation
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
),

-- 3. Vote counts by VoteType
VoteCount AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        vt.Name
)

-- Final output combining all the data
SELECT 
    pt.PostType,
    pt.PostCount,
    ua.DisplayName,
    ua.PostCount AS UserPostCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    vc.VoteType,
    vc.VoteCount
FROM 
    PostTypeCount pt
FULL OUTER JOIN 
    UserActivity ua ON true
FULL OUTER JOIN 
    VoteCount vc ON true
ORDER BY 
    pt.PostCount DESC, ua.PostCount DESC, vc.VoteCount DESC;
