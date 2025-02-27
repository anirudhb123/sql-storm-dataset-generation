WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CloseReason AS (
    SELECT 
        ph.PostId,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(cr.CloseReason, 'Not Closed') AS CloseReasonStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    CloseReason cr ON rp.PostId = cr.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;

WITH UserBadgeCount AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    UserBadgeCount ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    TotalBadges DESC, 
    u.Reputation DESC;

SELECT 
    p.Id, 
    p.Title, 
    array_agg(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
JOIN 
    unnest(string_to_array(p.Tags, '>,<')) AS tag_name ON TRUE
JOIN 
    Tags t ON t.TagName = TRIM(both '<>' from tag_name)
GROUP BY
    p.Id, p.Title
HAVING 
    COUNT(t.Id) > 3
ORDER BY 
    p.Id;
