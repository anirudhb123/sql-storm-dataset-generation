WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.Id, v.UpVotes, v.DownVotes
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.ViewCount,
        ps.CommentCount,
        ps.CloseCount,
        ps.ReopenCount,
        CASE 
            WHEN ur.Reputation >= 1000 THEN 'High Reputation' 
            WHEN ur.Reputation >= 100 THEN 'Medium Reputation' 
            ELSE 'Low Reputation' 
        END AS ReputationCategory,
        ur.BadgeCount
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.UserPostRank = 1 AND ps.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    Title,
    CreationDate,
    Score,
    UpVotes,
    DownVotes,
    ViewCount,
    CommentCount,
    CloseCount,
    ReopenCount,
    ReputationCategory,
    BadgeCount
FROM 
    PostMetrics
WHERE 
    (CloseCount > 0 OR ReopenCount > 0) 
    AND (Score IS NOT NULL AND Score > 10)
ORDER BY 
    Score DESC, CreationDate ASC
LIMIT 100
UNION ALL
SELECT 
    'Total Posts' AS Title,
    NULL AS CreationDate,
    COUNT(*) AS Score, 
    SUM(UpVotes) AS UpVotes,
    SUM(DownVotes) AS DownVotes,
    SUM(ViewCount) AS ViewCount,
    SUM(CommentCount) AS CommentCount,
    SUM(CloseCount) AS CloseCount,
    SUM(ReopenCount) AS ReopenCount,
    NULL AS ReputationCategory,
    NULL AS BadgeCount
FROM 
    PostMetrics;
