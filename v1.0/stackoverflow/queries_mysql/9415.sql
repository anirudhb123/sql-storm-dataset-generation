
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COALESCE(MAX(p.CreationDate), '1900-01-01') AS LatestPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > NOW() - INTERVAL 1 YEAR
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate > NOW() - INTERVAL 1 YEAR
    LEFT JOIN (
        SELECT 
            postId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            postId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalVotes,
        TotalBadges,
        LatestPostDate,
        @rank := IF(@prevTotalPosts = TotalPosts, @rank, @rank + 1) AS Rank,
        @prevTotalPosts := TotalPosts
    FROM 
        UserActivity, (SELECT @rank := 0, @prevTotalPosts := NULL) r
    ORDER BY 
        TotalPosts DESC, TotalVotes DESC
)
SELECT 
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalComments,
    ru.TotalVotes,
    ru.TotalBadges,
    ru.LatestPostDate
FROM 
    RankedUsers ru
WHERE 
    ru.Rank <= 10
ORDER BY 
    ru.Rank;
