WITH RecursivePostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Only interested in close, reopen, and delete events
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COALESCE(up.Reputation, 0) AS UserReputation,
        COALESCE(av.VoteCount, 0) AS TotalVotes,
        COALESCE(av.UpVoteCount, 0) AS UpVotes,
        COALESCE(av.DownVoteCount, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users up ON p.OwnerUserId = up.Id
    LEFT JOIN 
        AggregatedVotes av ON p.Id = av.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created within the last year
        AND p.PostTypeId = 1  -- Only questions
),
PostCloseStats AS (
    SELECT 
        rph.PostId,
        MAX(CASE WHEN rph.PostHistoryTypeId = 10 THEN rph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN rph.PostHistoryTypeId = 11 THEN rph.CreationDate END) AS ReopenedDate
    FROM 
        RecursivePostHistories rph
    WHERE 
        rph.HistoryRank = 1  -- Get the most recent close and reopen event
    GROUP BY 
        rph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.UserReputation,
    fp.TotalVotes,
    fp.UpVotes,
    fp.DownVotes,
    pcs.ClosedDate,
    pcs.ReopenedDate,
    (fp.UserReputation / NULLIF(fp.TotalVotes, 0)) AS ReputationPerVote -- Prevent division by zero
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostCloseStats pcs ON fp.PostId = pcs.PostId
ORDER BY 
    fp.TotalVotes DESC, 
    fp.CreationDate DESC -- Order by most votes and then by creation date
LIMIT 100; -- Limit to top 100 posts
