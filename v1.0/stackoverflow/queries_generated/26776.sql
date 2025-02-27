WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId, 0)) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS TagUsageCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY TagUsageCount DESC
    LIMIT 10
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.TotalPosts,
    ru.Questions,
    ru.Answers,
    ru.TotalViews,
    ru.TotalVotes,
    pt.TagName,
    pt.TagUsageCount
FROM RankedUsers ru
JOIN PopularTags pt ON pt.TagUsageCount > 5 -- Only include users who are associated with popular tags 
WHERE ru.Reputation > 1000 -- Filter for high-reputation users
ORDER BY ru.ReputationRank, pt.TagUsageCount DESC;
