WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  -- Include close, reopen, delete, undelete events
),
UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(UP.CreationDate, MIN(RPH.CreationDate)) AS ClosedDate,
        MIN(CASE WHEN RPH.PostHistoryTypeId = 10 THEN RPH.CreationDate END) AS ClosedTimestamp
    FROM 
        Posts p 
    LEFT JOIN 
        RecursivePostHistory RPH ON p.Id = RPH.PostId AND RPH.rn = 1
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Close event
    WHERE 
        ph.CreationDate IS NOT NULL
    GROUP BY 
        p.Id, p.Title, UP.CreationDate
),
PostDetails AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.ClosedDate,
        COALESCE(uv.UpVotes, 0) AS UpVotes,
        COALESCE(uv.DownVotes, 0) AS DownVotes,
        COALESCE(uv.CloseVotes, 0) AS CloseVotes,
        COALESCE(cp.ClosedTimestamp, '1970-01-01 00:00:00'::timestamp) AS ClosedTimestamp
    FROM 
        ClosedPosts cp
    LEFT JOIN 
        UserVotes uv ON cp.PostId = uv.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ClosedDate,
    pd.UpVotes,
    pd.DownVotes,
    pd.CloseVotes,
    CASE 
        WHEN pd.ClosedTimestamp IS NULL THEN 'Not Closed'
        WHEN pd.CloseVotes > 5 THEN 'Popular Close'
        ELSE 'Standard Close' 
    END AS CloseSeverity,
    CASE 
        WHEN pd.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS Status
FROM 
    PostDetails pd
ORDER BY 
    pd.UpVotes DESC, pd.CloseVotes DESC
LIMIT 100;

-- This query retrieves a list of posts that have been closed, their closing details, and user activity related to those posts.
-- It uses CTEs to build a hierarchy of relevant post history events, while also evaluating votes and determining post statuses.
