
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.OwnerUserId,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.PostTypeId IN (1, 2) 
),
PostAnalysis AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.AnswerCount,
        r.RankScore,
        r.RankViews,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts r
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    GROUP BY 
        r.PostId, r.Title, r.CreationDate, r.ViewCount, r.Score, r.AnswerCount, r.RankScore, r.RankViews, u.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        GROUP_CONCAT(CONCAT(ph.Comment, ' on ', ph.CreationDate) SEPARATOR '; ') AS ClosureDetails
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.AnswerCount,
    pa.RankScore,
    pa.RankViews,
    pa.OwnerDisplayName,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    COALESCE(cph.ClosureDetails, 'No closure history') AS ClosureHistory
FROM 
    PostAnalysis pa
LEFT JOIN 
    ClosedPostHistory cph ON pa.PostId = cph.PostId
WHERE 
    pa.RankScore <= 10 OR pa.RankViews <= 10
ORDER BY 
    pa.RankScore, pa.RankViews DESC;
