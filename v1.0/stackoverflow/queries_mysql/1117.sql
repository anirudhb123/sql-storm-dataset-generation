
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ScoreRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
PostSummaries AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Author,
        tp.CreationDate,
        tp.Score,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        (tp.UpVotes - tp.DownVotes) AS NetVotes,
        CASE 
            WHEN tp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        TopPosts tp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes,
    ps.CommentStatus,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    PostSummaries ps
LEFT JOIN 
    Posts p ON p.Id = ps.PostId
LEFT JOIN 
    (SELECT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
     FROM Posts p
     INNER JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                  SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                  SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - 
                 CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_name
GROUP BY 
    ps.PostId, ps.Title, ps.Author, ps.CreationDate, ps.Score, ps.CommentCount, ps.UpVotes, ps.DownVotes, ps.NetVotes, ps.CommentStatus
ORDER BY 
    ps.NetVotes DESC
LIMIT 10;
