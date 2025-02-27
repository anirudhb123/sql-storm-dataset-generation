WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    WHERE 
        CreationDate > CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        NVL(rv.UpVotes, 0) AS UpVotes,
        NVL(rv.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN rc.PostId IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN (
        SELECT 
            DISTINCT ph.PostId 
        FROM 
            PostHistory ph
        WHERE 
            ph.PostHistoryTypeId = 10 -- Post Closed
    ) rc ON rp.PostId = rc.PostId
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.Score,
    cd.UpVotes,
    cd.DownVotes,
    cd.PostStatus,
    CASE 
        WHEN cd.Score > 100 THEN 'Highly Upvoted'
        WHEN cd.Score BETWEEN 50 AND 100 THEN 'Moderately Upvoted'
        ELSE 'Low Votes'
    END AS VoteCategory,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = cd.PostId) AS CommentCount,
    STRING_AGG(b.Name, ', ') AS BadgeNames
FROM 
    CombinedData cd
LEFT JOIN 
    Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = cd.PostId) 
WHERE 
    cd.Rank <= 5 -- Top 5 per post type
GROUP BY 
    cd.PostId, cd.Title, cd.ViewCount, cd.Score, cd.UpVotes, cd.DownVotes, cd.PostStatus
ORDER BY 
    cd.Score DESC, cd.ViewCount DESC;
