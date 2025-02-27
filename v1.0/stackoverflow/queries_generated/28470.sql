WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        BadgeCount,
        UpVotes,
        DownVotes,
        TotalViews,
        RANK() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS ActivityRank
    FROM 
        UserActivity
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
TopPostsByComments AS (
    SELECT 
        PostId,
        Title,
        CommentCount,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM 
        TopPosts
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS UsageCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserName,
    u.PostCount,
    u.CommentCount,
    u.BadgeCount,
    u.UpVotes,
    u.DownVotes,
    u.TotalViews,
    p.Title AS MostCommentedPost,
    c.CommentCount AS MostCommentedCount,
    p.TotalUpVotes,
    p.TotalDownVotes,
    t.TagName AS PopularTag,
    t.UsageCount AS TagUsageCount
FROM 
    TopActiveUsers u
LEFT JOIN 
    TopPostsByComments p ON u.UserId = p.PostId
LEFT JOIN 
    TopTags t ON true
WHERE 
    u.ActivityRank <= 10
ORDER BY 
    u.PostCount DESC, u.TotalViews DESC, p.CommentRank;
