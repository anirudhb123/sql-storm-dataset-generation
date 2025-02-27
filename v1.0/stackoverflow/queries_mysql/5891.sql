
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) * (vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(DISTINCT v.Id) * (vt.Name = 'DownMod') AS DownvoteCount,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user_id := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    CROSS JOIN 
        (SELECT @row_number := 0, @current_user_id := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
