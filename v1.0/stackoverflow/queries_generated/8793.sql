WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        pt.Name AS PostType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(LEFT(p.Tags, LENGTH(p.Tags) - 2), '><') AS tag_array ON p.Id = POSTS.Id
    LEFT JOIN 
        Tags t ON tag_array::text = t.TagName
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.CreationDate, pt.Name
),
UserPostStats AS (
    SELECT 
        u.DisplayName,
        ups.UserId,
        COUNT(p.PostId) AS TotalPosts,
        SUM(COALESCE(ps.Score, 0)) AS TotalScore,
        SUM(COALESCE(ps.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(ps.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(ps.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(uvs.UpVotes, 0)) AS UpVotes,
        SUM(COALESCE(uvs.DownVotes, 0)) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStats ps ON p.Id = ps.PostId
    LEFT JOIN 
        UserVoteSummary uvs ON u.Id = uvs.UserId
    GROUP BY 
        u.DisplayName, ups.UserId
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.UpVotes,
    ups.DownVotes
FROM 
    UserPostStats ups
WHERE 
    ups.TotalPosts > 10
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC
LIMIT 50;
