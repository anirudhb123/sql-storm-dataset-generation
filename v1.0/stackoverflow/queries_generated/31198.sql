WITH RECURSIVE UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.AboutMe,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.LastActivityDate) AS LastActivity,
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.CreationDate, p.Score, p.Title
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        us.Score,
        us.CommentCount,
        us.VoteCount,
        us.LastActivity,
        ROW_NUMBER() OVER (PARTITION BY u.UserId ORDER BY us.Score DESC) AS ActivityRank
    FROM 
        UserScores us
    INNER JOIN 
        ActivePosts ap ON us.UserId = ap.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pt.Name AS PostType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '60 days'
)
SELECT 
    t.DisplayName AS TopUser,
    COUNT(DISTINCT ap.PostId) AS ActivePostsCount,
    SUM(ap.Score) AS TotalScore,
    AVG(ap.VoteCount) AS AvgVotes,
    STRING_AGG(DISTINCT r.PostType, ', ') AS RecentPostTypes,
    SUM(CASE WHEN r.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureCount,
    SUM(CASE WHEN r.PostHistoryTypeId IN (24) THEN 1 ELSE 0 END) AS EditCount
FROM 
    TopUsers t
INNER JOIN 
    ActivePosts ap ON t.UserId = ap.OwnerUserId
LEFT JOIN 
    RecentPostHistory r ON ap.PostId = r.PostId
WHERE 
    t.ActivityRank = 1
GROUP BY 
    t.DisplayName
ORDER BY 
    ActivePostsCount DESC, TotalScore DESC;
