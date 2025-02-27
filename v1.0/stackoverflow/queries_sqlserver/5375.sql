
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0) 
        AND p.PostTypeId IN (1, 2)
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId = 4 THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId = 5 THEN 1 ELSE 0 END) AS BodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    ph.LastEditDate,
    ph.TitleEdits,
    ph.BodyEdits
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated ph ON rp.PostId = ph.PostId
WHERE 
    rp.RankScore <= 10
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
