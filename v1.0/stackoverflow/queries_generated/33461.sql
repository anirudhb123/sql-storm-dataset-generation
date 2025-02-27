WITH RecursivePosts AS (
    SELECT p.Id,
           p.Title,
           p.Score,
           p.CreationDate,
           p.ParentId,
           1 AS Depth
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start with top-level questions
    UNION ALL
    SELECT p.Id,
           p.Title,
           p.Score,
           p.CreationDate,
           p.ParentId,
           rp.Depth + 1
    FROM Posts p
    JOIN RecursivePosts rp ON p.ParentId = rp.Id
    WHERE p.PostTypeId = 2  -- Join with answers
),
PostWithVoteCounts AS (
    SELECT p.Id,
           p.Title,
           p.Score,
           COALESCE(v.UpVotes, 0) AS UpVotes,
           COALESCE(v.DownVotes, 0) AS DownVotes,
           COALESCE(v.ViewCount, 0) AS ViewCount,
           p.CreationDate,
           COUNT(DISTINCT cm.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY rp.Depth ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId,
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
               SUM(CASE WHEN VoteTypeId IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments cm ON p.Id = cm.PostId
    LEFT JOIN RecursivePosts rp ON p.Id = rp.Id
    WHERE p.CreationDate >= '2020-01-01'
    GROUP BY p.Id, p.Title, p.Score, v.UpVotes, v.DownVotes, v.ViewCount, p.CreationDate, rp.Depth
),
RankedPosts AS (
    SELECT *,
           (UpVotes - DownVotes) AS NetScore,
           RANK() OVER (ORDER BY NetScore DESC, CreationDate DESC) AS OverallRank
    FROM PostWithVoteCounts
)
SELECT *,
       CASE 
           WHEN OverallRank <= 50 THEN 'Top Posts'
           ELSE 'Other Posts'
       END AS Category,
       CASE 
           WHEN UpVotes = 0 AND DownVotes = 0 THEN 'No Votes'
           ELSE 
               CASE 
                   WHEN UpVotes > DownVotes THEN 'Majority Upvotes'
                   ELSE 'Majority Downvotes'
               END
       END AS VotingAnalysis,
       (SELECT string_agg(DISTINCT TagName, ', ') 
        FROM Tags t 
        WHERE t.Id IN (SELECT unnest(string_to_array(Tags, '<>'))::int)) AS Tags
FROM RankedPosts
WHERE Rank <= 10;  -- Limit to top 10 posts by score within each depth

This SQL query constructs a recursive common table expression (CTE) to find all posts and their hierarchical relationships, gathers voting data with conditions, and categorizes posts based on voting patterns while providing tag aggregation for easy analysis. It employs window functions for ranking and partitions the results intelligently.
