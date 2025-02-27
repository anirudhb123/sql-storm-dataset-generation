WITH TagUsage AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS UsersContributed
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[]) 
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
PostEngagement AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        COUNT(DISTINCT PostLinks.RelatedPostId) AS LinkedPostCount,
        MAX(Posts.LastActivityDate) AS LastActivity
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        PostLinks ON Posts.Id = PostLinks.PostId
    WHERE 
        Posts.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.Title
),
TopTags AS (
    SELECT 
        TagUsage.TagName,
        TagUsage.PostCount,
        TagUsage.TotalViews,
        TagUsage.AvgReputation,
        TagUsage.UsersContributed,
        RANK() OVER (ORDER BY TagUsage.TotalViews DESC) AS TagRank
    FROM 
        TagUsage
),
TopEngagedPosts AS (
    SELECT 
        PostEngagement.PostId,
        PostEngagement.Title,
        PostEngagement.CommentCount,
        PostEngagement.VoteCount,
        PostEngagement.LinkedPostCount,
        PostEngagement.LastActivity,
        RANK() OVER (ORDER BY PostEngagement.VoteCount DESC, PostEngagement.CommentCount DESC) AS EngagementRank
    FROM 
        PostEngagement
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AvgReputation,
    tt.UsersContributed,
    tep.Title AS MostEngagedPost,
    tep.CommentCount,
    tep.VoteCount,
    tep.LinkedPostCount,
    tep.LastActivity
FROM 
    TopTags tt
JOIN 
    TopEngagedPosts tep ON tt.TagName = ANY(string_to_array(substring(tep.Title, 2, length(tep.Title) - 2), '><'))
WHERE 
    tt.TagRank <= 10 AND tep.EngagementRank <= 5
ORDER BY 
    tt.TotalViews DESC, tep.VoteCount DESC;
