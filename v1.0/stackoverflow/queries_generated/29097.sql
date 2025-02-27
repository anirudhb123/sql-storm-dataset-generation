WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.State IN ('Closed', 'Deleted') THEN 1 ELSE 0 END) AS UnavailablePosts,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        DATEDIFF(CURDATE(), MIN(p.CreationDate)) AS DaysActive
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS CountOfPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        CountOfPosts DESC
    LIMIT 10
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATE_SUB(NOW(), INTERVAL 1 YEAR)
    GROUP BY 
        p.Id
)

SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.UnavailablePosts,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.DaysActive,
    pt.TagName,
    pa.Title AS PopularPostTitle,
    pa.ViewCount AS PopularPostViews,
    pa.CommentCount AS PopularPostComments,
    pa.UpVotes AS PopularPostUpVotes,
    pa.DownVotes AS PopularPostDownVotes
FROM 
    UserStatistics us
LEFT JOIN 
    PopularTags pt ON pt.CountOfPosts = (
        SELECT COUNT(*) FROM Posts p2 WHERE p2.Tags LIKE CONCAT('%', pt.TagName, '%') AND p2.OwnerUserId = us.UserId
    )
LEFT JOIN 
    PostActivity pa ON pa.UpVotes > 10
ORDER BY 
    us.TotalPosts DESC, pt.CountOfPosts DESC
LIMIT 20;
