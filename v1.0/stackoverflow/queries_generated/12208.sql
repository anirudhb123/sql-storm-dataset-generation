-- Performance Benchmarking Query
WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN AcceptAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    pt.Name AS PostTypeName,
    pc.TotalPosts,
    pc.AcceptedAnswers,
    COUNT(DISTINCT us.UserId) AS TotalUsers,
    AVG(us.Reputation) AS AvgReputation,
    SUM(us.BadgeCount) AS TotalBadges,
    SUM(pa.CommentCount) AS TotalComments,
    SUM(pa.UpVotes) AS TotalPostUpVotes,
    SUM(pa.DownVotes) AS TotalPostDownVotes
FROM 
    PostCounts pc
JOIN 
    PostTypes pt ON pc.PostTypeId = pt.Id
JOIN 
    UserStatistics us ON us.UserId IS NOT NULL
JOIN 
    PostActivity pa ON pa.PostId IS NOT NULL
GROUP BY 
    pt.Name, pc.TotalPosts, pc.AcceptedAnswers;
