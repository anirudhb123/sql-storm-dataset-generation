WITH RecursivePosts AS (
    -- Recursive CTE to find all descendants of questions
    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
VoteDetails AS (
    -- CTE to summarize votes by post
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostHistories AS (
    -- CTE to fetch post history information 
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 END) AS CloseDeleteCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
CombinedData AS (
    -- Joining all the CTEs together with the main Posts table
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        rp.Level,
        vd.UpVotes,
        vd.DownVotes,
        vd.AcceptedVotes,
        ph.ClosedDate,
        ph.DeletedDate,
        ph.CloseDeleteCount
    FROM Posts p
    LEFT JOIN RecursivePosts rp ON p.Id = rp.Id
    LEFT JOIN VoteDetails vd ON p.Id = vd.PostId
    LEFT JOIN PostHistories ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Only consider posts from the last year
      AND (vd.UpVotes - vd.DownVotes) > 0 -- Only consider posts with a positive score
)

-- Final selection
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.Level,
    cd.UpVotes,
    cd.DownVotes,
    cd.AcceptedVotes,
    cd.ClosedDate,
    cd.DeletedDate,
    cd.CloseDeleteCount,
    CASE 
        WHEN cd.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN cd.DeletedDate IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END AS Status,
    DENSE_RANK() OVER (ORDER BY cd.UpVotes DESC) AS Rank
FROM CombinedData cd
ORDER BY Rank
FETCH FIRST 10 ROWS ONLY; -- Return top 10 ranked posts
