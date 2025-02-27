
WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostRanked AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
),
BadgesRanked AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(DISTINCT b.Name ORDER BY b.Name ASC SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name ASC SEPARATOR ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    uv.UpVotes,
    uv.DownVotes,
    COALESCE(br.BadgeCount, 0) AS TotalBadges,
    COALESCE(br.BadgeNames, 'None') AS BadgeNames,
    pr.PostId,
    pr.Title,
    pr.Score,
    pd.PostHistoryTypes,
    pd.LastUpdate
FROM 
    Users u
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    BadgesRanked br ON u.Id = br.UserId
LEFT JOIN 
    PostRanked pr ON pr.RecentPostRank = 1 AND u.Id = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = pr.PostId
    )
LEFT JOIN 
    PostDetails pd ON pr.PostId = pd.PostId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    pr.Score DESC
LIMIT 50;
