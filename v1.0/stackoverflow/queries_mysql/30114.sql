
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS RankByScore,
        @prev_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := '') AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MIN(ph.CreationDate) AS FirstChange,
        MAX(ph.CreationDate) AS LastChange
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
),
PostAnalysis AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ph.HistoryCount,
        ph.FirstChange,
        ph.LastChange,
        CASE 
            WHEN ph.HistoryCount > 5 THEN 'Frequent Changes'
            ELSE 'Infrequent Changes'
        END AS ChangeFrequency,
        @post_rank := @post_rank + 1 AS PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryCTE ph ON rp.PostId = ph.PostId
    CROSS JOIN (SELECT @post_rank := 0) AS vars2
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.AnswerCount,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.HistoryCount,
    pa.FirstChange,
    pa.LastChange,
    pa.ChangeFrequency,
    pa.PostRank,
    COALESCE(u.DisplayName, 'Deleted User') AS UserDisplayName,
    COALESCE(pf.FavoriteCount, 0) AS TotalFavorites
FROM 
    PostAnalysis pa
LEFT JOIN 
    Users u ON pa.PostId IN (SELECT ParentId FROM Posts WHERE Id = u.Id) 
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS FavoriteCount FROM Votes WHERE VoteTypeId = 5 GROUP BY PostId) pf ON pa.PostId = pf.PostId
WHERE 
    pa.PostRank <= 10  
ORDER BY 
    pa.Score DESC,
    pa.PostRank;
