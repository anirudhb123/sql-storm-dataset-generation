
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.PostTypeId,
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
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ptt.Name AS PostTypeName
FROM 
    RankedPosts rp
JOIN 
    PostTypes ptt ON rp.PostTypeId = ptt.Id
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.CreationDate DESC, rp.UpVotes DESC;
