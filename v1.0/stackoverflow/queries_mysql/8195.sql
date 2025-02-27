
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpVoteCount,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM 
             (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
              SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         WHERE 
             CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS t ON TRUE
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) r
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.CommentCount, 
    rp.UpVoteCount, 
    rp.Rank,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
