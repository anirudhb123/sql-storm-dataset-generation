WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(SUM(b.UserId IS NOT NULL) OVER (PARTITION BY p.Id), 0) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 AND -- Filter for questions
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days' -- Last 30 days
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.UpVotes,
    rp.DownVotes,
    rp.TotalBadges,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 -- Top 10 trending questions
ORDER BY 
    rp.Rank;
