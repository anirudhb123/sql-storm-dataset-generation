WITH RECURSIVE UserPostHierarchy AS (
    -- Base case: Selecting users with their posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000  -- Consider only users with significant reputation

    UNION ALL

    -- Recursive case: Find comments made by those users
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        c.PostId,
        p.Title,
        c.CreationDate AS PostCreationDate,
        p.Score
    FROM 
        Users u
    JOIN 
        Comments c ON u.Id = c.UserId
    JOIN 
        Posts p ON c.PostId = p.Id
    WHERE 
        u.Reputation > 1000  -- Consider only users with significant reputation
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CloseReasonDetail AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Only considering close events
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.UserId,
    pp.PostId,
    pp.Title,
    pp.PostCreationDate,
    pp.Score,
    COALESCE(cv.CloseCount, 0) AS CloseCount,
    COALESCE(cv.CloseReasons, 'Not Closed') AS CloseReasons,
    vs.VoteCount,
    vs.Upvotes,
    vs.Downvotes
FROM 
    UserPostHierarchy u
JOIN 
    PostVoteSummary vs ON u.PostId = vs.PostId
LEFT JOIN 
    CloseReasonDetail cv ON u.PostId = cv.PostId
WHERE 
    (pp.Score >= 5 OR cv.CloseCount > 0)  -- Return posts with significant score or closed posts
ORDER BY 
    u.UserId, pp.PostCreationDate DESC;
