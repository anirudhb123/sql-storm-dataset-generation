
WITH PostVoteCounts AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        (
            SELECT GROUP_CONCAT(t.TagName SEPARATOR ', ') 
            FROM (
                SELECT t.TagName 
                FROM Tags t 
                JOIN (
                    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName 
                    FROM (
                        SELECT a.N + b.N * 10 + 1 n 
                        FROM 
                            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                    ) numbers 
                    WHERE numbers.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) 
                ) AS tag
                WHERE t.TagName = tag.TagName
            ) AS t
        ) AS TagName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostVoteCounts v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURDATE() - INTERVAL 30 DAY
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.TotalVotes,
    pd.TagName,
    RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank
FROM PostDetail pd
WHERE pd.ViewCount > 100 
ORDER BY pd.Score DESC, pd.ViewCount DESC
LIMIT 10;
