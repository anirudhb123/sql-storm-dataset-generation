WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.Score,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.Tags
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::varchar[]) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived, -- Upvotes for the user's posts
        SUM(v.VoteTypeId = 3) AS DownVotesReceived, -- Downvotes for the user's posts
        COUNT(DISTINCT p.Id) AS PostsCount, -- Total posts made by user
        COUNT(DISTINCT c.Id) AS CommentsCount -- Total comments made by user
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        UserID,
        DisplayName,
        PostsCount,
        CommentsCount,
        UpVotesReceived,
        DownVotesReceived,
        RANK() OVER (ORDER BY PostsCount DESC, UpVotesReceived DESC) AS EngagementRank
    FROM 
        UserEngagement
)
SELECT 
    r.Title AS PostTitle,
    r.ViewCount AS TotalViews,
    r.Score AS PostScore,
    r.CommentCount AS TotalComments,
    t.TagName AS PopularTag,
    u.DisplayName AS TopEngagedUser,
    u.PostsCount AS UserPosts,
    u.CommentsCount AS UserComments
FROM 
    RankedPosts r
JOIN 
    PopularTags t ON r.Tags LIKE '%' || t.TagName || '%'
JOIN 
    TopEngagedUsers u ON r.RankScore <= 10 AND u.EngagementRank <= 5 -- Join only top-ranked posts and users
WHERE 
    r.RankScore <= 10 -- Select top 10 highest scored posts
ORDER BY 
    r.Score DESC, u.UpVotesReceived DESC;
