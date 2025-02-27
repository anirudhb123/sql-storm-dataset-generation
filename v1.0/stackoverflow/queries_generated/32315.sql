WITH RecursivePostHierarchy AS (
    -- CTE to recursively get all answers related to questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        ph.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  -- Selecting Answers
),

PostStatistics AS (
    SELECT 
        post.PostId,
        post.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS UpVoteCount,
        COALESCE(MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS DownVoteCount,
        SUM(CASE WHEN ph.Level = 1 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        RecursivePostHierarchy post
    LEFT JOIN 
        Comments c ON c.PostId = post.PostId
    LEFT JOIN 
        Votes v ON v.PostId = post.PostId 
    LEFT JOIN 
        Users u ON u.Id = post.OwnerUserId
    GROUP BY 
        post.PostId, post.Title, u.DisplayName
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.OwnerDisplayName,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.AnswerCount,
        ph.LastEditDate,
        ph.CreateDate
    FROM 
        PostStatistics ps
    JOIN 
        Posts ph ON ps.PostId = ph.Id
    WHERE 
        ph.ClosedDate IS NOT NULL
),

LatestVotes AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastVoteDate
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    cp.Title,
    cp.OwnerDisplayName,
    cp.CommentCount,
    cp.VoteCount,
    cp.UpVoteCount,
    cp.DownVoteCount,
    cp.AnswerCount,
    cp.LastEditDate,
    cp.CreateDate,
    lv.LastVoteDate
FROM 
    ClosedPosts cp
LEFT JOIN 
    LatestVotes lv ON cp.PostId = lv.PostId
ORDER BY 
    cp.VoteCount DESC,
    cp.CommentCount DESC
LIMIT 100;
