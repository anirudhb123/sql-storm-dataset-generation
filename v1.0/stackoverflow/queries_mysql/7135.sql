
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number:=IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type:=p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN 
        (SELECT @row_number:=0, @prev_post_type:=NULL) AS vars
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.Author, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.UpVotes - tp.DownVotes > 0 THEN 'Positive Engagement'
        WHEN tp.UpVotes - tp.DownVotes < 0 THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementLevel
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
