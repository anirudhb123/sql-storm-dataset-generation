WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.CreationDate,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.Id
), 

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, 
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS Status
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.ClosedDate
),

FinalOutput AS (
    SELECT 
        rh.Title AS QuestionTitle,
        rh.CreationDate AS QuestionDate,
        um.DisplayName AS UserDisplayName,
        pm.ViewCount,
        pm.Score,
        pm.UpVotes,
        pm.DownVotes,
        pm.Status,
        rh.Level AS AnswerLevel
    FROM 
        RecursivePostHierarchy rh
    JOIN 
        Posts p ON rh.Id = p.Id
    JOIN 
        UserReputation um ON p.OwnerUserId = um.UserId
    JOIN 
        PostMetrics pm ON p.Id = pm.Id
)

SELECT 
    fo.QuestionTitle,
    fo.QuestionDate,
    fo.UserDisplayName,
    fo.ViewCount,
    fo.Score,
    fo.UpVotes,
    fo.DownVotes,
    fo.Status,
    CASE 
        WHEN fo.Level > 1 THEN 'Answer'
        ELSE 'Question'
    END AS PostType
FROM 
    FinalOutput fo
WHERE 
    fo.UpVotes > 5 AND 
    fo.Score >= 0
ORDER BY 
    fo.QuestionDate DESC;
