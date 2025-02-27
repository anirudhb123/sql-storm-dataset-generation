WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostsCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON t.Id = pt.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        PostsCount DESC
    LIMIT 5
)
SELECT 
    u.DisplayName,
    u.Upvotes,
    u.Downvotes,
    ps.PostId,
    ps.Title,
    ps.CommentsCount,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    pt.TagName
FROM 
    UserVotes u
JOIN 
    PostStats ps ON u.PostsCount > 0
JOIN 
    PostLinks pl ON ps.PostId = pl.PostId
JOIN 
    PopularTags pt ON pl.RelatedPostId = pt.PostId
WHERE 
    u.Upvotes > u.Downvotes
ORDER BY 
    u.Upvotes DESC, ps.TotalUpvotes DESC;
