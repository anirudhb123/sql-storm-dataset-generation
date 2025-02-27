WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount
),
PostStats AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.Score AS PostScore,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes + rp.DownVotes > 0 THEN (rp.UpVotes::float / (rp.UpVotes + rp.DownVotes)) * 100 
            ELSE 0 
        END AS UpvotePercentage,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top Post for User'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    ps.Id,
    ps.Title,
    ps.PostScore,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.UpvotePercentage,
    u.DisplayName AS OwnerDisplayName,
    CASE 
        WHEN ps.PostScore < 0 THEN 'Low Score'
        WHEN ps.PostScore BETWEEN 1 AND 10 THEN 'Average Score'
        ELSE 'High Score' 
    END AS ScoreCategory,
    CASE 
        WHEN ps.CommentCount IS NULL THEN 'No Comments'
        ELSE ps.CommentCount::text || ' Comments'
    END AS CommentInfo
FROM 
    PostStats ps
LEFT JOIN 
    Users u ON ps.OwnerUserId = u.Id
WHERE 
    ps.UpvotePercentage > 50
ORDER BY 
    ps.PostScore DESC, ps.ViewCount DESC
LIMIT 100;
