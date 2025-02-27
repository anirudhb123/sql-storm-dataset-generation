
WITH TagUsage AS (
    SELECT 
        value AS Tag,
        Posts.Id AS PostId,
        Posts.Title,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        AVG(Users.Reputation) AS AvgUserReputation
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') AS TagSplit
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Posts.Id, Posts.Title, Tag
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(PostId) AS UsageCount
    FROM 
        TagUsage
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TagStats AS (
    SELECT 
        tu.Tag,
        AVG(tu.CommentCount) AS AvgComments,
        SUM(tu.UpvoteCount) AS TotalUpvotes,
        SUM(tu.DownvoteCount) AS TotalDownvotes,
        AVG(tu.AvgUserReputation) AS AvgReputation
    FROM 
        TagUsage tu
    JOIN 
        PopularTags pt ON tu.Tag = pt.Tag
    GROUP BY 
        tu.Tag
)
SELECT 
    ts.Tag,
    ts.AvgComments,
    ts.TotalUpvotes,
    ts.TotalDownvotes,
    ts.AvgReputation,
    CASE 
        WHEN ts.TotalUpvotes > ts.TotalDownvotes THEN 'Positive'
        WHEN ts.TotalUpvotes < ts.TotalDownvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TagStats ts
ORDER BY 
    ts.TotalUpvotes DESC, ts.TotalDownvotes ASC;
