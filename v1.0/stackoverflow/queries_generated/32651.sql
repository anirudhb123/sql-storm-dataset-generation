WITH RecursivePostScore AS (
    SELECT p.Id AS PostId, 
           p.Score AS PostScore,
           p.ParentId,
           1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions
    
    UNION ALL
    
    SELECT p.Id,
           rp.PostScore + COALESCE((SELECT SUM(v.BountyAmount) 
                                      FROM Votes v 
                                      WHERE v.PostId = p.Id 
                                      AND v.VoteTypeId IN (8, 9)), 0) AS PostScore, 
           p.ParentId,
           Level + 1
    FROM Posts p
    INNER JOIN RecursivePostScore rp ON p.ParentId = rp.PostId
    WHERE p.PostTypeId = 2  -- Only answers
),
RankedPosts AS (
    SELECT p.Id,
           p.Title,
           rp.PostScore,
           RANK() OVER (ORDER BY rp.PostScore DESC) AS ScoreRank,
           u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN RecursivePostScore rp ON p.Id = rp.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
),
TopPosts AS (
    SELECT *,
           COUNT(*) OVER (PARTITION BY ScoreRank) AS RankCount
    FROM RankedPosts
    WHERE ScoreRank <= 10
),
PostTags AS (
    SELECT p.Id AS PostId,
           STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName) 
    GROUP BY p.Id
)
SELECT tp.Title,
       tp.ScoreRank,
       tp.PostScore,
       tp.OwnerDisplayName,
       COALESCE(pt.Tags, 'No Tags') AS Tags,
       tp.RankCount,
       CASE 
           WHEN tp.RankCount > 1 THEN 'Tied'
           ELSE 'Unique'
       END AS RankType
FROM TopPosts tp
LEFT JOIN PostTags pt ON tp.Id = pt.PostId
ORDER BY tp.ScoreRank, tp.PostScore DESC;
