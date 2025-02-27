
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        (@userRank := IF(@prevUserId = rp.OwnerUserId, @userRank + 1, 1)) AS UserRank,
        (@prevUserId := rp.OwnerUserId) AS dummy
    FROM 
        RecentPosts rp, (SELECT @userRank := 0, @prevUserId := NULL) AS vars
    ORDER BY 
        rp.OwnerUserId, rp.Score DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    bd.BadgeCount,
    bd.BadgeNames,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    CASE 
        WHEN pd.UserRank <= 3 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus,
    (SELECT MAX(p.Score) 
     FROM Posts p 
     WHERE p.OwnerUserId = pd.OwnerUserId) AS HighestScore
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges bd ON u.Id = bd.UserId
WHERE 
    pd.UserRank <= 100
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC;
