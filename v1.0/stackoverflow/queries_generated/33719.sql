WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 1 AS Level
    FROM Users
    WHERE Id = (SELECT MIN(Id) FROM Users)  -- Starting point for the hierarchy

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id > uh.Id  -- Tree structure for the sake of this demo
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,  -- Count Upvotes
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,  -- Count Downvotes
        COUNT(c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Only recent posts
    GROUP BY p.Id
),

PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(*) AS ChangeCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),

CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ph.LastChangeDate,
        ph.ChangeCount,
        ROW_NUMBER() OVER (PARTITION BY ps.PostId ORDER BY ph.LastChangeDate DESC) AS ChangeOrder
    FROM PostStats ps
    LEFT JOIN PostHistoryAnalysis ph ON ps.PostId = ph.PostId
),

FinalReport AS (
    SELECT 
        ch.DisplayName,
        cs.Title,
        cs.UpVotes,
        cs.DownVotes,
        cs.CommentCount,
        cs.LastChangeDate,
        cs.ChangeCount,
        CASE 
            WHEN cs.UpVotes - cs.DownVotes > 0 THEN 'Popular'
            WHEN cs.UpVotes - cs.DownVotes < 0 THEN 'Unpopular'
            ELSE 'Neutral'
        END AS PostStatus
    FROM CombinedStats cs
    JOIN UserHierarchy ch ON cs.UpVotes > 10  -- Include only if UpVotes are greater than 10 for demo
    WHERE cs.ChangeOrder = 1  -- Latest change
)

SELECT 
    DisplayName,
    Title,
    UpVotes,
    DownVotes,
    CommentCount,
    LastChangeDate,
    ChangeCount,
    PostStatus
FROM FinalReport
ORDER BY UpVotes DESC, DownVotes ASC
LIMIT 100;  -- Limit to top 100 results
