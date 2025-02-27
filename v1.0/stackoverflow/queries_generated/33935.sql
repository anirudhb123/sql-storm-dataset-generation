WITH RecursivePosts AS (
    SELECT p.Id, p.Title, p.Score, p.CreationDate, 0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Select only questions
    UNION ALL
    SELECT p2.Id, p2.Title, p2.Score, p2.CreationDate, rp.Level + 1
    FROM Posts p2
    INNER JOIN Posts rp ON p2.ParentId = rp.Id
    WHERE rp.PostTypeId = 1  -- Join with parent questions
),
PostAggregates AS (
    SELECT
        rp.Id,
        MAX(rp.Score) AS MaxScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUBSTRING(rp.Title, 1, 30) AS ShortTitle
    FROM RecursivePosts rp
    LEFT JOIN Comments c ON rp.Id = c.PostId
    LEFT JOIN Votes v ON rp.Id = v.PostId AND v.VoteTypeId = 2  -- UpMod votes
    GROUP BY rp.Id
),
TopPosts AS (
    SELECT
        pa.Id,
        pa.MaxScore,
        pa.CommentCount,
        pa.ShortTitle,
        RANK() OVER (ORDER BY pa.MaxScore DESC) AS ScoreRank
    FROM PostAggregates pa
    WHERE pa.MaxScore IS NOT NULL
)

SELECT
    tp.Id AS PostId,
    tp.ShortTitle,
    tp.MaxScore,
    tp.CommentCount,
    tp.ScoreRank,
    COALESCE(ut.Reputation, 0) AS UserReputation,
    UPDATES.TotalUpdates
FROM TopPosts tp
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS TotalUpdates
    FROM PostHistory
    WHERE CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Consider updates from the last year
    GROUP BY PostId
) AS UPDATES ON tp.Id = UPDATES.PostId
LEFT JOIN Users ut ON EXTRACT(YEAR FROM ut.CreationDate) = EXTRACT(YEAR FROM NOW()  -- Only consider users created in the current year
      AND ut.Reputation > 0
WHERE tp.ScoreRank <= 10  -- Get top 10 posts
ORDER BY tp.MaxScore DESC, tp.Id;
