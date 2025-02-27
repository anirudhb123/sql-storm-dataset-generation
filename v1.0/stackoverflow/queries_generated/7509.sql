WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.PostId) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, ',')::int[]) 
    GROUP BY 
        t.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    pt.TagName,
    pt.TagUsageCount
FROM 
    UserStats us
JOIN 
    popularTags pt ON us.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags LIKE '%' || pt.TagName || '%')
ORDER BY 
    us.Reputation DESC, pt.TagUsageCount DESC
LIMIT 50;
