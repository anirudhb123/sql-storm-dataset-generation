
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts p
         JOIN (SELECT @rownum := @rownum + 1 AS n FROM 
               (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n,
               (SELECT @rownum := 0) r) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
    ORDER BY 
        p.CreationDate DESC
    LIMIT 10
),
PostStats AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Posts p WHERE FIND_IN_SET(t.TagName, rp.Tags)) AS TagCount
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.TagCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.Score * 1.0 / NULLIF(ps.TagCount, 0) AS ScorePerTag,
    ps.Score * 1.0 / NULLIF(ps.CommentCount, 0) AS ScorePerComment,
    ps.ViewCount * 1.0 / NULLIF(ps.CommentCount, 0) AS ViewPerComment
FROM 
    PostStats ps
WHERE 
    ps.Score > 0 
ORDER BY 
    ScorePerTag DESC, ScorePerComment DESC;
