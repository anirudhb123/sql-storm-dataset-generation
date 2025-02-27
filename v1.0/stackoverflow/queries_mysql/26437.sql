
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(1) AS TagCount,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM Posts p
         JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS Tag
    ON true
    JOIN 
        Tags t ON t.TagName = Tag.TagName
    GROUP BY 
        p.Id
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Score
),
PostAnalytics AS (
    SELECT 
        pt.PostId,
        pt.TagCount,
        pt.TagsList,
        ps.UpVotes,
        ps.DownVotes,
        ps.NetVotes,
        ps.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate
    FROM 
        PostTagCounts pt
    JOIN 
        PostScores ps ON pt.PostId = ps.PostId
    JOIN 
        Posts p ON pt.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.Score,
    pa.TagCount,
    pa.TagsList,
    pa.UpVotes,
    pa.DownVotes,
    pa.NetVotes,
    @rank := @rank + 1 AS Rank
FROM 
    PostAnalytics pa,
    (SELECT @rank := 0) r
WHERE 
    pa.TagCount > 3 AND pa.Score > 0
ORDER BY 
    pa.NetVotes DESC, pa.Score DESC 
LIMIT 10;
