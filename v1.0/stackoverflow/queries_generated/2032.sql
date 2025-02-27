WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Id, 0)) AS TotalComments,
        SUM(COALESCE(v.Id, 0)) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    ue.DisplayName,
    ue.PostCount,
    ue.TotalViews,
    ue.TotalComments,
    ue.TotalVotes,
    tt.TagName,
    CASE 
        WHEN ue.PostCount > 0 THEN (ue.TotalVotes::decimal / ue.PostCount) 
        ELSE 0 
    END AS AverageVotesPerPost
FROM 
    UserEngagement ue
CROSS JOIN 
    TopTags tt
WHERE 
    ue.EngagementRank <= 10 
    AND AvgVotesPerPost IS NOT NULL
ORDER BY 
    ue.TotalViews DESC, ue.TotalVotes DESC;
