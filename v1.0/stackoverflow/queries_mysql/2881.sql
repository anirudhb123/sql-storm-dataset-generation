
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @rank := IF(@prev_owner = p.OwnerUserId, @rank + 1, 1) AS Rank,
        @prev_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN 
        (SELECT @rank := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    rp.CommentCount,
    CASE WHEN rp.Rank = 1 THEN 'Top Post' ELSE 'Regular Post' END AS PostCategory,
    CASE 
        WHEN rp.Score > 5 THEN 'Highly Engaged'
        WHEN rp.Score BETWEEN 1 AND 5 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.CommentCount > 10 OR rp.Rank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
