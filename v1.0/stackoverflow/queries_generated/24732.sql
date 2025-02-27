WITH RankedVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId
    WHERE v.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreatedDate
    FROM Users u
    WHERE u.Reputation IS NOT NULL
      AND u.CreationDate < (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
PostAggregate AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT COALESCE(v.UserId, -1)) AS TotalVoters,
        MAX(b.Date) AS LastBadgeDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    GROUP BY p.Id, p.Title
),
FilteredPosts AS (
    SELECT 
        pa.Id,
        pa.Title,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        pa.TotalVoters,
        ur.Reputation,
        ur.DisplayName
    FROM PostAggregate pa
    INNER JOIN UserReputation ur ON ur.UserId = pa.OwnerUserId
    WHERE pa.CommentCount > 5
      AND pa.UpVotes > pa.DownVotes
      AND ur.Reputation > 100
)
SELECT 
    fp.Title,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.TotalVoters,
    COALESCE(rv.VoteTypeId, 0) AS LastVoteType,
    fp.Reputation,
    fp.DisplayName,
    CASE
        WHEN fp.TotalVoters > 10 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN fp.CommentCount > 10 THEN 'Hot Topic'
        ELSE 'Regular Topic'
    END AS TopicHeat,
    CASE 
        WHEN fp.UpVotes IS NULL THEN 'No Upvotes'
        ELSE 'Has Upvotes'
    END AS UpvoteStatus
FROM FilteredPosts fp
LEFT JOIN RankedVotes rv ON fp.Id = rv.PostId AND rv.VoteRank = 1
WHERE (fp.Title ILIKE '%SQL%' OR fp.Title ILIKE '%Database%')
   OR (fp.CommentCount > 15 AND fp.Reputation > 200)
ORDER BY fp.CommentCount DESC, fp.UpVotes DESC
LIMIT 100 OFFSET 0;

-- In this query:
-- The Common Table Expressions (CTEs) are used to break down complex logic into more manageable components.
-- `RankedVotes` identifies the latest vote type per post.
-- `UserReputation` filters users based on certain criteria.
-- `PostAggregate` aggregates data for posts, including counts of comments and votes.
-- `FilteredPosts` filters posts based on conditions related to comments and votes as well as user reputation.
-- Finally, the main SELECT composes the final output, utilizing outer joins and conditional logic for diverse analytic insights.
