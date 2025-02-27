WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Counting only Upvotes and Downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.RankScore,
    CASE 
        WHEN rp.VoteCount > 100 THEN 'High Engagement'
        WHEN rp.VoteCount BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
WHERE 
    rp.RankScore <= 10  -- Top 10 Posts by Rank Score
ORDER BY 
    rp.RankScore, rp.Score DESC;
