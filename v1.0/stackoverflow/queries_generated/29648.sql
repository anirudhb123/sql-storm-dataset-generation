WITH TagCounts AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT post.Id) AS PostCount,
        SUM(post.ViewCount) AS TotalViews,
        SUM(post.Score) AS TotalScore
    FROM 
        Tags AS tag
    JOIN 
        Posts AS post ON post.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY 
        tag.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagPopularityRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 0
),
UserEngagement AS (
    SELECT 
        user.Id AS UserId,
        user.DisplayName,
        SUM(vote.Id) AS TotalVotes,
        COUNT(DISTINCT post.Id) AS PostsContributed,
        SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users AS user
    LEFT JOIN 
        Posts AS post ON post.OwnerUserId = user.Id
    LEFT JOIN 
        Votes AS vote ON vote.PostId = post.Id
    WHERE 
        user.Reputation > 100
    GROUP BY 
        user.Id, user.DisplayName
),
EngagementSummary AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalVotes,
        ue.PostsContributed,
        ue.UpVotes,
        ue.DownVotes,
        tt.TagName
    FROM 
        UserEngagement AS ue
    JOIN 
        TopTags AS tt ON tt.TagPopularityRank <= 10
    WHERE 
        ue.TotalVotes > 0
)
SELECT 
    es.DisplayName AS User,
    es.PostsContributed AS TotalPosts,
    es.UpVotes AS TotalUpVotes,
    es.DownVotes AS TotalDownVotes,
    STRING_AGG(DISTINCT es.TagName, ', ') AS PopularTags
FROM 
    EngagementSummary AS es
GROUP BY 
    es.UserId, es.DisplayName
ORDER BY 
    es.TotalPosts DESC;
