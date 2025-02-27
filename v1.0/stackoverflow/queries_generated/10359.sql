-- Performance Benchmarking Query to analyze post activity and user engagement on Stack Overflow

WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= '2023-01-01' -- filtering posts created in 2023
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= '2023-01-01' -- filtering users created in 2023
    GROUP BY 
        u.Id, u.DisplayName
)

-- Final select to combine insights
SELECT 
    e.PostId,
    e.Title,
    e.PostTypeId,
    e.CommentCount,
    e.VoteCount,
    e.UpVotes,
    e.DownVotes,
    e.AcceptedAnswers,
    u.UserId,
    u.DisplayName,
    u.PostsCount,
    u.BadgesCount,
    u.TotalViews
FROM 
    PostEngagement e
JOIN 
    Users u ON e.PostId = u.Id
ORDER BY 
    e.Score DESC; -- Assuming you want to sort by the score of the posts
