WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND
        p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        RankScore,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.ViewCount,
    trp.CommentCount,
    trp.UpVoteCount,
    trp.DownVoteCount,
    COALESCE(pH.LastEdited, 'Never') AS LastEdited,
    pH.HistoryTypes
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostHistoryAggregates pH ON trp.PostId = pH.PostId
ORDER BY 
    trp.Score DESC,
    trp.ViewCount DESC;

