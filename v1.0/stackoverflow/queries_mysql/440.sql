
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        @row_num := IF(@ownerUserId = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @ownerUserId := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0, @ownerUserId := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.PostRank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 AND
        rp.Score > (SELECT AVG(Score) FROM Posts) AND
        rp.CommentCount IS NOT NULL
),
FinalResults AS (
    SELECT 
        fp.Id,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.CommentCount,
        fp.UpVoteCount,
        fp.DownVoteCount,
        CASE 
            WHEN fp.Score > 100 THEN 'Hot' 
            WHEN fp.Score BETWEEN 50 AND 100 THEN 'Trending' 
            ELSE 'Normal' 
        END AS PostCategory,
        @dense_rank := IF(@prev_score = fp.Score, @dense_rank, @dense_rank + 1) AS ScoreRank,
        @prev_score := fp.Score
    FROM 
        FilteredPosts fp,
        (SELECT @dense_rank := 0, @prev_score := NULL) AS rank_vars
)
SELECT 
    fr.Id,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.CommentCount,
    fr.UpVoteCount,
    fr.DownVoteCount,
    fr.PostCategory,
    fr.ScoreRank
FROM 
    FinalResults fr
WHERE 
    fr.ScoreRank <= 10
ORDER BY 
    fr.Score DESC;
