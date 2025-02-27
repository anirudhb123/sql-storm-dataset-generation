
WITH RecursiveTags AS (
    SELECT 
        p.Id AS PostId, 
        VALUE AS Tag
    FROM 
        Posts p 
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        SUM(ISNULL(c.Score, 0)) AS TotalCommentScores,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes 
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
        ROW_NUMBER() OVER (ORDER BY ue.TotalPosts DESC) AS Rank
    FROM 
        UserEngagement ue
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
