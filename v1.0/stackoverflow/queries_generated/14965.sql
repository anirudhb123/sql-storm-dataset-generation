-- Performance Benchmarking SQL Query for StackOverflow Schema

-- This query retrieves statistics for posts including counts of comments, votes, and average score,
-- while also retrieving summarized user information for the top contributors to the posts.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(v.VoteTypeId) AS AverageVoteType -- Assuming 1 = Accepted, 2 = UpMod, etc.
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.AverageVoteType,
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.TotalScore
FROM 
    PostStats ps
JOIN 
    UserPostStats ups ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ups.UserId)
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
