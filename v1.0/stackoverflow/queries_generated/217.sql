WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score >= 10
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    up.TotalBadges,
    up.TotalVotes,
    pvc.UpVotes,
    pvc.DownVotes
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = up.Id)
LEFT JOIN 
    UserScores up ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostVoteCounts pvc ON pvc.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    up.TotalVotes DESC NULLS LAST
LIMIT 100;
