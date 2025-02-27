-- Performance Benchmarking Query
-- This query measures the relationship and data retrieval performance for Users, Posts, and their respective votes and comments.

WITH UserPostAggregation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        pt.Name AS PostType 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    uga.UserId,
    uga.DisplayName,
    uga.PostCount,
    uga.QuestionCount,
    uga.AnswerCount,
    uga.UpVoteCount,
    uga.DownVoteCount,
    uga.CommentCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.PostType
FROM 
    UserPostAggregation uga
LEFT JOIN 
    PostDetail pd ON pd.OwnerDisplayName = uga.DisplayName
ORDER BY 
    uga.Reputation DESC, uga.PostCount DESC;
