
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        @row_number := IF(@current_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @current_post_type := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_post_type := NULL) AS var
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT PostId, Title, OwnerDisplayName, Score, ViewCount, CreationDate, CommentCount, UpVoteCount, DownVoteCount
    FROM RankedPosts
    WHERE Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.OwnerDisplayName,
    t.Score,
    t.ViewCount,
    t.CreationDate,
    t.CommentCount,
    t.UpVoteCount,
    t.DownVoteCount,
    CASE 
        WHEN t.UpVoteCount > t.DownVoteCount THEN 'Positive'
        WHEN t.UpVoteCount < t.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts t
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
