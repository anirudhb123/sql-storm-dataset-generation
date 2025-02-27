WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        0 AS Level,
        p.OwnerUserId,
        p.AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.Score,
        a.CreationDate,
        r.Level + 1 AS Level,
        a.OwnerUserId,
        a.AcceptedAnswerId
    FROM 
        Posts a
    INNER JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes - Downvotes AS Score,
        RANK() OVER (ORDER BY Upvotes - Downvotes DESC) AS Rank
    FROM 
        UserScores
)
SELECT 
    pt.Name AS PostType,
    r.PostId,
    r.Title,
    r.Score AS PostScore,
    r.Level,
    u.DisplayName AS Owner,
    u.EmailHash,
    u.Reputation,
    t.Rank AS UserRank
FROM 
    RecursiveCTE r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON r.AcceptedAnswerId = pt.Id
JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    r.Score > 0 AND
    (r.CreationDate >= NOW() - INTERVAL '1 month') 
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;
