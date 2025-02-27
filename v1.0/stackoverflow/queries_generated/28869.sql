WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Tags
    JOIN 
        Posts p ON Tags.Id = ANY(string_to_array(p.Tags, '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS Contributions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year' -- Users created in the last year
    GROUP BY 
        u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
),
EngagedUsers AS (
    SELECT 
        DisplayName,
        Contributions,
        TotalViews,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Contributions DESC) AS ContributionRank
    FROM 
        UserActivity
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AvgScore,
    eu.DisplayName AS TopContributor,
    eu.Contributions AS ContributorCount,
    eu.UpVotes AS ContributorUpVotes,
    eu.DownVotes AS ContributorDownVotes
FROM 
    TopTags tt
JOIN 
    EngagedUsers eu ON eu.ContributionRank = 1
WHERE 
    tt.Rank <= 5; -- Top 5 tags by views
