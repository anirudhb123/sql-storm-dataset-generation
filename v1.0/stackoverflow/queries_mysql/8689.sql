
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS AuthorDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
        AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, U.DisplayName, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.AuthorDisplayName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.CreationDate DESC;
