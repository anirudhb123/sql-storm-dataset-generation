
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
        t.TagName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostVoteCounts v ON p.Id = v.PostId
    OUTER APPLY (
        SELECT STRING_AGG(t.TagName, ', ') AS TagName
        FROM STRING_SPLIT(p.Tags, '><') AS tag
        JOIN Tags t ON t.TagName = tag.value
    ) AS t
    WHERE p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE)
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
