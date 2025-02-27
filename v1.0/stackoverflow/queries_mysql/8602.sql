
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, u.DisplayName, p.Score, p.Title, p.CreationDate, p.PostTypeId
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    tp.*,
    CASE 
        WHEN tp.Score > 100 THEN 'High Scoring'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Moderate Scoring'
        ELSE 'Low Scoring'
    END AS ScoreCategory,
    CONCAT('https://stackoverflow.com/posts/', tp.PostId) AS PostLink
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
