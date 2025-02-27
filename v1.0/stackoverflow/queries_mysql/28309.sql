
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpVoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ), 0) AS DownVoteCount,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY 
        AND p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.*,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS AllTags
    FROM 
        RecentPosts rp
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '<>', n.n), '<>', -1) as tag
         FROM RecentPosts rp
         INNER JOIN (SELECT a.N + b.N * 10 + 1 n
                      FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                            UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
                           (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                            UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
                      ) n
         WHERE n.n <= 1 + (LENGTH(rp.Tags) - LENGTH(REPLACE(rp.Tags, '<>', ''))) 
        ) AS tag ON 
        tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.OwnerDisplayName, 
        rp.Score, rp.ViewCount, rp.CommentCount, rp.UpVoteCount, 
        rp.DownVoteCount, rp.Tags
),
RankedPosts AS (
    SELECT 
        fp.*,
        @row_number := IF(@prev_score = fp.Score, @row_number, @row_number + 1) AS ScoreRank,
        @prev_score := fp.Score
    FROM 
        FilteredPosts fp, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY 
        fp.Score DESC, fp.ViewCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.AllTags,
    rp.ScoreRank
FROM 
    RankedPosts rp
WHERE 
    rp.ScoreRank <= 10  
ORDER BY 
    rp.ScoreRank;
