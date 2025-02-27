WITH RecursivePostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostData r ON r.PostId = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Answers only
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),

RankedUsers AS (
    SELECT 
        UserId,
        Reputation,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
)

SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.Score,
    p.CreationDate,
    p.ViewCount,
    r.UserId,
    r.Reputation,
    r.UserRank,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.VoteCount, 0) AS VoteCount,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RecursivePostData p
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.PostId = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.PostId = v.PostId
JOIN 
    RankedUsers r ON r.UserId = p.OwnerUserId
WHERE 
    p.Level = 1  -- Only top-level questions
ORDER BY 
    p.Score DESC,
    p.ViewCount DESC
LIMIT 100;
