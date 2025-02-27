WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.AnswerCount,
    ur.QuestionCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate
FROM 
    UserReputation ur
LEFT JOIN 
    RecentPosts rp ON ur.UserId = rp.OwnerUserId AND rp.rn = 1
ORDER BY 
    ur.Reputation DESC,
    ur.PostCount DESC
LIMIT 10;

WITH RankedChanges AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
),
ChangeCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(r.ChangeRank) AS ChangeCount
    FROM 
        Posts p
    LEFT JOIN 
        RankedChanges r ON p.Id = r.PostId
    GROUP BY 
        p.Id
)
SELECT 
    c.PostId,
    c.ChangeCount,
    p.Title
FROM 
    ChangeCounts c
JOIN 
    Posts p ON c.PostId = p.Id
WHERE 
    c.ChangeCount > 0
ORDER BY 
    c.ChangeCount DESC
LIMIT 5;

SELECT 
    DISTINCT T.TagName,
    COUNT(p.Id) AS PostCount
FROM 
    Tags T
LEFT JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', T.TagName, '%')
GROUP BY 
    T.TagName
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    PostCount DESC;

SELECT 
    U.DisplayName,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
    COUNT(DISTINCT p.Id) AS PostsCount
FROM 
    Users U
LEFT JOIN 
    Posts p ON U.Id = p.OwnerUserId
LEFT JOIN 
    Votes V ON p.Id = V.PostId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    Upvotes DESC, Downvotes ASC;

WITH UserVoteStats AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
UserActivities AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(uvs.TotalUpvotes, 0) AS Upvotes,
        COALESCE(uvs.TotalDownvotes, 0) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        UserVoteStats uvs ON U.Id = uvs.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    LastAccessDate,
    Upvotes,
    Downvotes
FROM 
    UserActivities
WHERE 
    Upvotes - Downvotes > 10
ORDER BY 
    (Upvotes - Downvotes) DESC
LIMIT 10;
