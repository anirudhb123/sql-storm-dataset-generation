WITH PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagsArray,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
TagWithCount AS (
    SELECT 
        unnest(TagsArray) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        PostsWithTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount
    FROM 
        TagWithCount
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.UpVotesReceived,
    ue.DownVotesReceived,
    tt.Tag,
    tt.PostCount
FROM 
    UserEngagement ue
CROSS JOIN 
    TopTags tt
ORDER BY 
    ue.UpVotesReceived DESC,
    ue.TotalPosts DESC,
    tt.PostCount DESC;
