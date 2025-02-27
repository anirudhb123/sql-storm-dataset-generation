WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentCloseAction
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        COALESCE(cp.Comment, 'No recent closure actions') AS RecentClosure
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId AND cp.RecentCloseAction = 1
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.CommentCount,
    trp.UpVoteCount,
    trp.RecentClosure,
    CASE
        WHEN trp.Score IS NULL THEN 'No Score'
        WHEN trp.Score < 0 THEN 'Negative Score'
        ELSE 'Non-negative Score'
    END AS ScoreDescription
FROM 
    TopRankedPosts trp
WHERE 
    (trp.CommentCount > 0 OR trp.UpVoteCount > 10)
ORDER BY 
    trp.Score DESC, trp.CommentCount DESC;
