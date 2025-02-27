
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(UNIX_TIMESTAMP(v.CreationDate)) AS AvgVoteDate,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalVotes,
    @row_num := @row_num + 1 AS Rank
FROM 
    UserActivity ua, (SELECT @row_num := 0) r
ORDER BY 
    ua.TotalPosts DESC;
