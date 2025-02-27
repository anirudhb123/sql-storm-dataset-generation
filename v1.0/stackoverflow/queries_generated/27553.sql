WITH UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        MAX(p.CreationDate) AS LastPostDate,
        AVG(DATEDIFF(day, p.CreationDate, GETDATE())) AS AveragePostAgeDays
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT TOP 10 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        LastPostDate,
        AveragePostAgeDays
    FROM 
        UserActivities
    ORDER BY 
        TotalPosts DESC, TotalComments DESC
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreateDate,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.Score > 10
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
UserPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    mau.DisplayName,
    mau.TotalPosts,
    mau.TotalComments,
    mau.TotalUpvotes,
    mau.TotalDownvotes,
    mau.LastPostDate,
    mau.AveragePostAgeDays,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score,
    pp.ViewCount,
    pp.Tags,
    upl.RelatedPostsCount
FROM 
    MostActiveUsers mau
JOIN 
    PopularPosts pp ON uu.UserId = pp.OwnerUserId
JOIN 
    UserPostLinks upl ON pp.PostId = upl.PostId
ORDER BY 
    mau.TotalUpvotes DESC, mau.TotalPosts DESC;
