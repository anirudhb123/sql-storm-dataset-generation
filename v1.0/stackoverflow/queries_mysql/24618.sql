
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1))) AS tag 
         FROM Posts p 
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
), PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top'
            WHEN rp.Rank <= 3 THEN 'Top 3'
            ELSE 'Other'
        END AS RankCategory,
        COALESCE(ph.Comment, 'No close reason') AS LastCloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 
)
SELECT 
    ps.Author,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.RankCategory,
    ps.LastCloseReason,
    CASE 
        WHEN ps.Score = 0 THEN 'No Score Yet'
        WHEN ps.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreDescription,
    COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
    COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
FROM 
    PostStats ps
LEFT JOIN 
    Votes v ON ps.PostId = v.PostId
WHERE 
    ps.Score > 0 OR ps.LastCloseReason IS NOT NULL
GROUP BY 
    ps.Author, ps.Title, ps.Score, ps.ViewCount, ps.RankCategory, ps.LastCloseReason
ORDER BY 
    ps.Score DESC, UpVotes DESC
LIMIT 100 OFFSET 0;
