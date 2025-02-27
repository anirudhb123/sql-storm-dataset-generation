-- Performance Benchmarking SQL Query
-- This query evaluates the relationships between Posts, Users, and Votes to assess the performance of read operations on the schema.

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostDetailStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS LinkCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.UpVotes,
        ups.DownVotes,
        ups.TotalScore,
        pds.PostId,
        pds.Title,
        pds.CreationDate,
        pds.Score AS PostScore,
        pds.ViewCount,
        pds.AnswerCount,
        pds.CommentCount,
        pds.LinkCount
    FROM 
        UserPostStats ups
    JOIN 
        PostDetailStats pds ON ups.UserId = pds.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    UpVotes,
    DownVotes,
    TotalScore,
    PostId,
    Title,
    CreationDate,
    PostScore,
    ViewCount,
    AnswerCount,
    CommentCount,
    LinkCount
FROM 
    FinalStats
ORDER BY 
    TotalScore DESC, PostCount DESC;
