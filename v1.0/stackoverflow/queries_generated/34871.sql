WITH RecursiveUserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.EmailHash,
        0 AS RecursiveLevel
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.EmailHash,
        r.RecursiveLevel + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserScores r ON u.Id = r.UserId
    WHERE 
        u.Reputation > r.Reputation
),

RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
),

ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  -- Closed posts
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    r.RecursiveLevel,
    pp.Title AS TopPostTitle,
    pp.Score AS TopPostScore,
    pp.ViewCount AS TopPostViews,
    cp.CloseReason AS LastCloseReason,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes
FROM 
    RecursiveUserScores u
LEFT JOIN 
    (SELECT * FROM RankedPosts WHERE PostRank = 1) pp ON u.Id = pp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON pp.Id = cp.PostId
LEFT JOIN 
    PostStatistics ps ON pp.Id = ps.PostId
WHERE 
    u.Views > 5000
ORDER BY 
    u.Reputation DESC,
    ps.UpVotes DESC;
