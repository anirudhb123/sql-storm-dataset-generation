WITH RecursiveUserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate, 
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id, 
        u.Reputation, 
        u.CreationDate, 
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserReputation r ON u.Reputation < r.Reputation
    WHERE 
        LEVEL < 5
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 6) AS CloseVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 7) AS ReopenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        PHT.Name AS PostHistoryType, 
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month'
),
AggregatedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
        COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
        COALESCE(ps.CloseVotes, 0) AS TotalCloseVotes,
        COALESCE(ps.ReopenVotes, 0) AS TotalReopenVotes,
        MAX(rn) AS LatestPostHistory
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStatistics ps ON p.Id = ps.PostId
    LEFT JOIN 
        RecentPostHistory rph ON p.Id = rph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.CreationDate,
    ap.TotalUpVotes,
    ap.TotalDownVotes,
    ap.TotalCloseVotes,
    ap.TotalReopenVotes,
    CASE 
        WHEN ap.TotalUpVotes > ap.TotalDownVotes THEN 'Positive'
        WHEN ap.TotalDownVotes > ap.TotalUpVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    u.DisplayName AS UserDisplayName,
    u.EmailHash,
    uu.Reputation AS UserReputationLevel
FROM 
    AggregatedPostData ap
LEFT JOIN 
    Users u ON ap.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = ap.PostId)
LEFT JOIN 
    RecursiveUserReputation uu ON u.Id = uu.Id
WHERE 
    ap.LatestPostHistory = 1
ORDER BY 
    ap.TotalUpVotes DESC, 
    ap.CreationDate DESC
LIMIT 100;
