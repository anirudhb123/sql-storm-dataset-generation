WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    u.DisplayName AS OwnerName,
    ps.PostCount,
    ps.UpvotedPosts,
    ps.DownvotedPosts,
    ps.AvgViewCount,
    pvs.VoteCount,
    pvs.UpVotes,
    pvs.DownVotes,
    r.Level
FROM 
    RecursivePostHierarchy r
JOIN 
    UserPostStats ps ON ps.UserId = r.PostId -- Join on UserId from UserPostStats (considering they own the post)
LEFT JOIN 
    PostVoteStats pvs ON pvs.PostId = r.PostId
JOIN 
    Users u ON u.Id = r.PostId -- Owner of the post
WHERE 
    r.Level <= 2 -- Limit to questions and their answers
ORDER BY 
    r.Level, pvs.VoteCount DESC;

-- This query constructs a hierarchy of posts (questions and answers) and calculates statistics for authors and votes,
-- utilizing a recursive common table expression (CTE), window functions,
-- complex joins, and handling NULLs through left joins.
