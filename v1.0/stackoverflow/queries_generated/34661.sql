WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalCommentScore,
        (UpVotes - DownVotes) AS NetScore,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        MostActiveUsers
    WHERE 
        PostCount > 0
)
SELECT 
    r.PostId,
    r.Title,
    r.Level,
    u.DisplayName AS Author,
    u.Reputation,
    th.TotalCommentScore AS CommentScore,
    th.NetScore AS UserScore
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    TopUsers th ON th.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = r.PostId)
LEFT JOIN 
    Users u ON u.Id = r.PostId
WHERE 
    r.Level <= 3
ORDER BY 
    r.Level, th.NetScore DESC, r.CreationDate DESC;
