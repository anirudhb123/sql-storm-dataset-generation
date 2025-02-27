WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
PostAggregates AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount + rp.DownVoteCount > 0 THEN
                (rp.UpVoteCount::float / (rp.UpVoteCount + rp.DownVoteCount)) * 100
            ELSE 0
        END AS VotePercentage
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.VotePercentage,
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalBountyEarned
FROM 
    PostAggregates pa
JOIN 
    Users u ON pa.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    UserScores us ON u.Id = us.UserId
WHERE 
    pa.VotePercentage > 50
ORDER BY 
    pa.Score DESC, 
    pa.ViewCount DESC
LIMIT 100
OFFSET 10;
