WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(u.Reputation) AS AverageReputation,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.AverageReputation,
    us.UpVotes,
    us.DownVotes,
    rp.Title AS MostRecentPost,
    rp.CreationDate AS RecentPostDate,
    tt.TagName,
    tt.PostCount
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
JOIN 
    TopTags tt ON tt.PostCount > (SELECT AVG(PostCount) FROM TopTags)
WHERE 
    us.AverageReputation IS NOT NULL
ORDER BY 
    us.TotalPosts DESC
LIMIT 
    10;
