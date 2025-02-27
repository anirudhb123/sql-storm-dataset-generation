WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.Rank
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
),
PostVoteSummary AS (
    SELECT 
        p.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        string_agg(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    ps.UpVotes,
    ps.DownVotes,
    p.CommentsCount,
    phs.HistoryTypes,
    CASE 
        WHEN p.Score > 10 THEN 'High Score'
        WHEN p.Score BETWEEN 1 AND 10 THEN 'Average Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts p
LEFT JOIN 
    PostVoteSummary ps ON p.PostId = ps.PostId
LEFT JOIN 
    PostHistorySummary phs ON p.PostId = phs.PostId
WHERE 
    phs.HistoryTypes IS NOT NULL
ORDER BY 
    p.CreationDate DESC;
