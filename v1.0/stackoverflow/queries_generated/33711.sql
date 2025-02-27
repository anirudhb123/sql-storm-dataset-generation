WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON p.ParentId = a.Id  -- Recursively join Answers to their Questions
    JOIN 
        RecursivePostHierarchy r ON a.Id = r.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPostDetails AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS PostCreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
)
SELECT 
    r.POSTID,
    r.Title,
    u.DisplayName AS Owner,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    pvs.Upvotes,
    pvs.Downvotes,
    pvs.TotalVotes,
    pd.PostCreationDate,
    pd.CloseReason
FROM 
    RecursivePostHierarchy r
JOIN 
    UserBadges u ON r.OwnerUserId = u.UserId
JOIN 
    PostVoteStats pvs ON r.PostId = pvs.PostId
LEFT JOIN 
    ClosedPostDetails pd ON r.PostId = pd.PostId
WHERE 
    r.Level = 1  -- Only top-level Questions
    AND (pvs.Upvotes - pvs.Downvotes) > 5  -- Filter questions with significantly more upvotes than downvotes
ORDER BY 
    r.Title, pd.PostCreationDate DESC;
