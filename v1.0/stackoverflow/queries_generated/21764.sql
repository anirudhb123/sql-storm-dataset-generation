WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS InitialCreationDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostsInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        RPH.InitialCreationDate,
        RPH.ClosedDate,
        UVS.TotalUpVotes,
        UVS.TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHistory RPH ON p.Id = RPH.PostId
    LEFT JOIN 
        UserVoteStats UVS ON p.OwnerUserId = UVS.UserId
    WHERE 
        p.Score > 0 AND 
        (RPH.ClosedDate IS NULL OR RPH.ClosedDate > CURRENT_TIMESTAMP - INTERVAL '30 days')
)
SELECT 
    PI.PostId,
    PI.Title,
    PI.ViewCount,
    PI.Score,
    PI.InitialCreationDate,
    COALESCE(NULLIF(PI.ClosedDate, '1970-01-01 00:00:00'), 'No Closure') AS ClosureStatus,
    PI.TotalUpVotes,
    PI.TotalDownVotes,
    CASE 
        WHEN PI.TotalUpVotes > PI.TotalDownVotes THEN 'Positive Impact'
        ELSE 'Negative or Neutral Impact' 
    END AS CommunityImpact,
    CONCAT('This post has ', PI.ViewCount, ' views and a score of ', PI.Score, 
           '. It was created on ', TO_CHAR(PI.InitialCreationDate, 'YYYY-MM-DD HH24:MI:SS'), 
           ' and ', 
           CASE WHEN PI.ClosedDate IS NOT NULL THEN 'is closed.' ELSE 'is still open.' END) AS StatusMessage
FROM 
    PostsInfo PI
WHERE 
    PI.PostRank <= 10
ORDER BY 
    PI.Score DESC, PI.ViewCount DESC
LIMIT 50;

