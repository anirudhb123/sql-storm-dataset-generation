
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        @row_number := IF(@current_partition = p.PostTypeId, @row_number + 1, 1) AS Ranking,
        @current_partition := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @current_partition := NULL) AS vars
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR 
        AND p.PostTypeId IN (1, 2)
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON p.Id = rp.PostId
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON tag.TagName IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        rp.Ranking <= 10 
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.CommentCount, rp.UpVoteCount, rp.DownVoteCount
)
SELECT 
    fp.*,
    @overall_rank := @overall_rank + 1 AS OverallRank
FROM 
    FilteredPosts fp, (SELECT @overall_rank := 0) AS init
ORDER BY 
    fp.CreationDate DESC;
