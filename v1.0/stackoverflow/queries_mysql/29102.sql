
WITH RecursiveTags AS (
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p 
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
        SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
        SELECT 10 
    ) numbers ON CHAR_LENGTH(p.Tags) -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
), 
TagCounts AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagFrequency 
    FROM 
        RecursiveTags 
    GROUP BY 
        Tag
), 
TopTags AS (
    SELECT 
        Tag, 
        TagFrequency 
    FROM 
        TagCounts 
    ORDER BY 
        TagFrequency DESC 
    LIMIT 10
), 
PostsWithTopTags AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        rt.Tag 
    FROM 
        Posts p 
    JOIN 
        RecursiveTags rt ON p.Id = rt.PostId 
    JOIN 
        TopTags t ON rt.Tag = t.Tag
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(IFNULL(c.Score, 0)) AS TotalCommentScores,
        SUM(IF(v.VoteTypeId = 2, 1, 0)) AS TotalUpVotes, 
        SUM(IF(v.VoteTypeId = 3, 1, 0)) AS TotalDownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id, u.DisplayName
), 
UserActivity AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalCommentScores,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserEngagement ue, (SELECT @rank := 0) r
    ORDER BY 
        ue.TotalPosts DESC
)
SELECT 
    p.PostId, 
    p.Title, 
    p.CreationDate, 
    p.Tag,
    ua.DisplayName AS User, 
    ua.TotalPosts,
    ua.TotalCommentScores,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM 
    PostsWithTopTags p 
JOIN 
    UserActivity ua ON p.PostId = ua.UserId
ORDER BY 
    p.CreationDate DESC, 
    ua.TotalPosts DESC;
