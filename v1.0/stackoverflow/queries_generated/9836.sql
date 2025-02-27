WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS RankByPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostsCount, 
        CommentsCount, 
        BadgesCount, 
        UpVotesCount, 
        DownVotesCount
    FROM 
        UserActivity
    WHERE 
        RankByPosts <= 10
)
SELECT 
    t.DisplayName,
    t.PostsCount,
    t.CommentsCount,
    t.BadgesCount,
    t.UpVotesCount,
    t.DownVotesCount,
    COALESCE(SUM(p.ViewCount), 0) AS TotalPostViews
FROM 
    TopActiveUsers t
LEFT JOIN 
    Posts p ON t.UserId = p.OwnerUserId
GROUP BY 
    t.UserId, 
    t.DisplayName, 
    t.PostsCount, 
    t.CommentsCount, 
    t.BadgesCount, 
    t.UpVotesCount, 
    t.DownVotesCount
ORDER BY 
    t.PostsCount DESC;
