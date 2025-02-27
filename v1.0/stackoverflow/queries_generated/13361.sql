-- Performance benchmarking query for StackOverflow schema
-- This query will return statistics on posts, users, and their interactions.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Filter for the last year
    GROUP BY 
        p.Id, u.DisplayName
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.PostCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalViews
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerDisplayName = us.DisplayName
ORDER BY 
    ps.CreationDate DESC; -- Order by post creation date
