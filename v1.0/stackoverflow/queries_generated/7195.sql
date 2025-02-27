WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
), 
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    us.DisplayName AS TopUser,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount
FROM 
    TopRankedPosts rp
JOIN 
    Users us ON rp.OwnerUserId = us.Id
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
