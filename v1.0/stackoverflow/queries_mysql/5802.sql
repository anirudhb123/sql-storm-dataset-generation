
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        @row_num := IF(@current_post_type_id = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @current_post_type_id := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0, @current_post_type_id := NULL) AS vars
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.Title,
    t.ViewCount,
    t.CommentCount,
    t.UpVoteCount,
    t.DownVoteCount,
    CASE 
        WHEN t.UpVoteCount + t.DownVoteCount > 0 THEN 
            ROUND((t.UpVoteCount * 1.0 / (t.UpVoteCount + t.DownVoteCount)) * 100, 2)
        ELSE 
            0 
    END AS UpVotePercentage
FROM 
    TopPosts t
ORDER BY 
    t.ViewCount DESC;
