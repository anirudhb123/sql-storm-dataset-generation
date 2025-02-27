WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts from the last year
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryFiltered AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months' -- Filter for history from the last 6 months
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    rp.RankScore,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(phf.HistoryTypes, 'None') AS RecentHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostHistoryFiltered phf ON rp.PostId = phf.PostId
WHERE 
    rp.RankScore <= 5 -- Get the top 5 posts by score in each post type
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC;

-- Include an interesting edge case with filtering - find out how many posts had a score drop due to downvotes
WITH ScoreDrops AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        LAG(p.Score) OVER (ORDER BY p.CreationDate) AS PreviousScore
    FROM 
        Posts p
    WHERE 
        p.Score > 0 -- Only consider posts with a positive score
)

SELECT 
    COUNT(*) AS PostsWithDecreasedScore
FROM 
    ScoreDrops sd
WHERE 
    sd.Score < sd.PreviousScore OR sd.PreviousScore IS NULL; -- Counting drops in score
