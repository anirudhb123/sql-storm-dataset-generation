WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT tag) AS TagCount,
        STRING_AGG(DISTINCT tag, ', ') AS TagsList
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),
TopQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        pt.Id AS PostTypeId,
        pt.VotesType,
        pt.CommentCount,
        pt.AnswerCount,
        COALESCE(tag_counts.TagCount, 0) AS TagCount,
        COALESCE(tag_counts.TagsList, '') AS TagsList
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostTagCounts tag_counts ON p.Id = tag_counts.PostId
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalViews,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.TotalComments,
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.TagsList
FROM 
    UserActivity u
JOIN 
    TopQuestions tq ON tq.OwnerUserId = u.UserId
ORDER BY 
    u.TotalViews DESC, u.TotalPosts DESC;
