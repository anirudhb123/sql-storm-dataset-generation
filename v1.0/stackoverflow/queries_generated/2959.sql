WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.PostId
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    rp.Id,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    COALESCE(rv.TotalVotes, 0) AS RecentVoteCount,
    COALESCE(as.AnswerCount, 0) AS AnswerCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 100 THEN 'High Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
LEFT JOIN 
    AnswerStats as ON rp.Id = as.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC NULLS LAST;
