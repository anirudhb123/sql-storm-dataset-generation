
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsAggregated
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.ID, 0) AS BadgeCount,
        COALESCE(b.Date, '1900-01-01') AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS ID, MAX(Date) AS Date
         FROM Badges
         GROUP BY UserId) b ON u.Id = b.UserId
), RecentVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(*) AS TotalVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    u.DisplayName AS Owner, 
    u.Reputation,
    COALESCE(uv.BadgeCount, 0) AS BadgeCount,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.TotalVotes, 0) AS TotalVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    rp.TagsAggregated,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score Yet'
        WHEN rp.Score = 0 THEN 'Neutral Score'
        WHEN rp.Score > 0 THEN 'Positive Score'
        ELSE 'Negative Score' 
    END AS ScoreClassification,
    (CASE 
        WHEN (SELECT COUNT(*) 
              FROM Comments c 
              WHERE c.PostId = rp.PostId AND c.UserId IS NULL) > 0 
        THEN 'Comments Awaiting Approval' 
        ELSE 'No Pending Comments' 
    END) AS CommentStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation uv ON u.Id = uv.UserId
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
