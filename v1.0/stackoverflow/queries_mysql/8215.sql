
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @rank := IF(@prevPostTypeId = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prevPostTypeId := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @rank := 0, @prevPostTypeId := NULL) AS vars
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.PostTypeId, p.Score DESC, p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        PostId, Title, Owner, CreationDate, Score, ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Owner,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Owner, tp.CreationDate, tp.Score, tp.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Owner,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetScore,
    @overallRank := @overallRank + 1 AS OverallRank
FROM 
    PostStatistics ps,
    (SELECT @overallRank := 0) AS rank_init
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
