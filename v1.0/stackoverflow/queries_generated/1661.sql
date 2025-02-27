WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), LatestPost AS (
    SELECT 
        ps.*, 
        us.DisplayName,
        us.Reputation,
        us.Upvotes,
        us.Downvotes
    FROM 
        PostStats ps
    LEFT JOIN 
        UserScore us ON ps.OwnerUserId = us.UserId
    WHERE 
        ps.rn = 1
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen Events
    GROUP BY 
        ph.PostId
)
SELECT 
    lp.PostId,
    lp.Title,
    lp.AnswerCount,
    lp.CommentCount,
    lp.ViewCount,
    lp.DisplayName AS OwnerDisplayName,
    lp.Reputation AS OwnerReputation,
    COALESCE(cp.LastClosedDate, 'Not Closed') AS LastClosedDate,
    COALESCE(cp.CloseReason, 'No Reason') AS CloseReason,
    lp.HasAcceptedAnswer,
    CASE 
        WHEN lp.HasAcceptedAnswer = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS IsAcceptedAnswerPresent
FROM 
    LatestPost lp
LEFT JOIN 
    ClosedPosts cp ON lp.PostId = cp.PostId
ORDER BY 
    lp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
