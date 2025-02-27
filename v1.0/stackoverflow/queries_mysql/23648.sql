
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.Score IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        ViewCount > 1000
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    uv.UpVotes,
    uv.DownVotes,
    COALESCE(CONCAT(IFNULL(ps.TagName, 'No Tags Found'), ' (Average Score: ', IFNULL(CAST(ps.AverageScore AS CHAR), '0'), ')'), 'No Tags Found') AS PopularTag
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostID = uv.PostId
LEFT JOIN 
    TagStatistics ps ON rp.Score > ps.AverageScore
WHERE 
    rp.ScoreRank <= 5 
    AND rp.TotalPosts > 10
ORDER BY 
    rp.Score DESC, 
    uv.UpVotes DESC
LIMIT 100;
