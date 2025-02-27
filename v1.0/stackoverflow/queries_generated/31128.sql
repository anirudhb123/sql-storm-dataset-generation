WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        CONCAT('--- ', p.Title) AS Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),

ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ClosedDate,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title, p.ClosedDate
),

AggregatedComments AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount,
        STRING_AGG(Text, '; ') AS AllComments
    FROM 
        Comments
    GROUP BY 
        PostId
)

SELECT 
    r.PostId,
    r.Title AS PostTitle,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(c.AllComments, 'No comments') AS Comments,
    COALESCE(cb.ClosedDate, 'Not Closed') AS ClosureDate,
    COALESCE(rp.Reputation, 'No Activity') AS TopReputationUser,
    COALESCE(ur.DisplayName, 'Anonymous') AS UserDisplayName,
    ur.ReputationRank
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    AggregatedComments c ON r.PostId = c.PostId
LEFT JOIN 
    ClosedPosts cb ON r.PostId = cb.Id
LEFT JOIN 
    UserReputation ur ON EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId IN (2, 3) AND v.UserId = ur.UserId)
WHERE 
    r.Level = 1 -- Main posts only
ORDER BY 
    r.Title;
