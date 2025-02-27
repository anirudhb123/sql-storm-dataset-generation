
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @prev_user := p.OwnerUserId,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, CommentCount, UpVotes, DownVotes, UserReputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.UserReputation,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.Score > 100 THEN 'High'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.UserReputation DESC, tp.Score DESC;
