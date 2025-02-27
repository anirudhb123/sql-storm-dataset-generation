
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
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.Tags
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived, 
        COUNT(DISTINCT p.Id) AS PostsCount, 
        COUNT(DISTINCT c.Id) AS CommentsCount 
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
    PopularTags t ON r.Tags LIKE CONCAT('%', t.TagName, '%')
JOIN 
    TopEngagedUsers u ON r.RankScore <= 10 AND u.EngagementRank <= 5 
WHERE 
    r.RankScore <= 10 
ORDER BY 
    r.Score DESC, u.UpVotesReceived DESC;
