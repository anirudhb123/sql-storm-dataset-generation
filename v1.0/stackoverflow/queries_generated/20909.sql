WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.PostTypeId,
           p.Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
           COALESCE(p.AcceptedAnswerId, -1) AS AnswerEligibility,
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM Posts p
    LEFT JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT PostId, Title, CreationDate, PostTypeId, Score, ViewCount, 
           CASE 
               WHEN AnswerEligibility <> -1 THEN 'Answered' 
               ELSE 'Unanswered' 
           END AS AnswerStatus,
           TagsList, CommentCount, UpVotes, DownVotes,
           NTILE(5) OVER (ORDER BY Score DESC) AS ScoreBucket
    FROM RankedPosts
    WHERE rn <= 10 -- Limit to the 10 most recent posts of each type
),
AggregatedViews AS (
    SELECT AnswerStatus, 
           COUNT(*) AS PostCount, 
           SUM(ViewCount) AS TotalViews,
           SUM(Score) AS TotalScore
    FROM FilteredPosts
    GROUP BY AnswerStatus
)
SELECT f.PostId, 
       f.Title, 
       f.CreationDate, 
       f.PostTypeId,
       f.Score, 
       f.ViewCount,
       f.AnswerStatus, 
       f.TagsList,
       f.CommentCount,
       f.UpVotes,
       f.DownVotes,
       a.PostCount,
       a.TotalViews,
       a.TotalScore,
       CASE 
           WHEN a.PostCount > 0 THEN (a.TotalScore::FLOAT / a.PostCount) 
           ELSE 0 
       END AS AverageScorePerPost,
       CASE 
           WHEN f.ViewCount IS NULL THEN 'No Views' 
           ELSE 'Has Views' 
       END AS ViewStatus,
       COALESCE(b.Name, 'No Badge') AS UserBadge
FROM FilteredPosts f
LEFT JOIN AggregatedViews a ON f.AnswerStatus = a.AnswerStatus
LEFT JOIN Badges b ON f.PostId = b.UserId
WHERE EXISTS (
    SELECT 1 
    FROM PostHistory ph 
    WHERE ph.PostId = f.PostId 
    AND ph.PostHistoryTypeId IN (10, 12) 
    AND ph.CreationDate >= NOW() - INTERVAL '1 year'
) 
ORDER BY f.CreationDate DESC
LIMIT 15 OFFSET 5;
