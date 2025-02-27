
WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ISNULL(uv.TotalVotes, 0) AS TotalVotes,
        ISNULL(uv.UpVotes, 0) AS UpVotes,
        ISNULL(uv.DownVotes, 0) AS DownVotes,
        ISNULL(ps.TotalPosts, 0) AS TotalPosts,
        ISNULL(ps.PositivePosts, 0) AS PositivePosts,
        ISNULL(ps.NegativePosts, 0) AS NegativePosts,
        ISNULL(ps.TotalComments, 0) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY ISNULL(uv.TotalVotes, 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        UserVotes uv ON u.Id = uv.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalVotes,
    UpVotes,
    DownVotes,
    TotalPosts,
    PositivePosts,
    NegativePosts,
    TotalComments,
    Rank
FROM 
    UserPostStats
WHERE 
    TotalPosts > 0
ORDER BY 
    Rank;
