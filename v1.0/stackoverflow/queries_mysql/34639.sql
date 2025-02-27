
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @row_number := IF(pt.Name = 'Question', @q_count := @q_count + 1, IF(pt.Name = 'Answer', @a_count := @a_count + 1, @other_count := @other_count + 1)) AS rn,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX( p.Tags, ',', numbers.n), ',', -1) AS tag_name
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers  
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_name ON tag_name IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    CROSS JOIN (SELECT @q_count := 0, @a_count := 0, @other_count := 0) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.VoteCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.VoteCount, rp.UpVotes, rp.DownVotes, rp.Tags
),
FilteredPosts AS (
    SELECT 
        pwc.*,
        CASE 
            WHEN pwc.Score > 10 THEN 'High Score'
            WHEN pwc.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory, 
        @post_rank := @post_rank + 1 AS PostRank
    FROM 
        PostWithComments pwc
    CROSS JOIN (SELECT @post_rank := 0) AS init
    ORDER BY pwc.Score DESC
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.VoteCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.ScoreCategory,
    CASE 
        WHEN fp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentsStatus
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
