WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) OVER (PARTITION BY p.Id) AS UpVotesCount,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) OVER (PARTITION BY p.Id) AS DownVotesCount
    FROM 
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.Score > 0 AND 
        p.CreationDate > current_date - interval '30 days'
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteTotal,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate > current_date - interval '14 days'
    GROUP BY 
        v.PostId
), FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 AND 
        b.Date >= current_date - interval '1 year'
    GROUP BY 
        b.UserId
), Final AS (
    SELECT 
        rp.PostId,
        rp.Title, 
        rp.Score,
        rp.UserPostRank,
        rv.VoteTotal,
        fb.BadgeCount,
        CASE 
            WHEN rv.LastVoteDate IS NULL THEN 'No recent votes'
            ELSE 'Recently voted'
        END AS VotingStatus,
        CASE 
            WHEN rp.UpVotesCount - rp.DownVotesCount > 0 THEN 'Positive' 
            ELSE 'Negative' 
        END AS ScoreStatus
    FROM 
        RankedPosts rp
        LEFT JOIN RecentVotes rv ON rp.PostId = rv.PostId
        LEFT JOIN FilteredBadges fb ON rp.AcceptedAnswerId = fb.UserId
    WHERE 
        rp.UserPostRank <= 5 AND 
        (fb.BadgeCount IS NULL OR fb.BadgeCount > 0) 
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.VoteTotal,
    f.VotingStatus,
    f.ScoreStatus
FROM 
    Final f
WHERE 
    f.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate > current_date - interval '30 days')
ORDER BY 
    f.Score DESC, f.VoteTotal DESC
LIMIT 10;

This complex SQL query achieves the following tasks:

1. **CTEs**: Uses multiple Common Table Expressions (CTEs) to break down the problem into smaller parts:
   - `RankedPosts`: Computes ranks for posts based on creation date per user, counts upvotes and downvotes.
   - `RecentVotes`: Calculates the total number of votes and the latest vote date per post in the last 14 days.
   - `FilteredBadges`: Counts gold badges earned by users in the last year.

2. **NULL logic**: Incorporates NULL checking to manage posts without votes and users without badges.

3. **Window Functions**: Uses `ROW_NUMBER()` and `SUM()` window functions to rank posts and count votes effectively.

4. **Complicated predicates/expressions**: The `CASE` statements handle different score and voting statuses dynamically, enabling complex conditional logic.

5. **Outer Joins**: Applies outer joins to ensure that all users and posts are taken into consideration, regardless of whether they have associated votes or badges.

6. **Bizarre semantics**: Uses implicit checks on vote counts and badge counts, including cases where badge count is NULL or greater than zero, making the logic elaborate.

The final selection retrieves the top posts with statistics based on recent activity, ensuring the results are meaningful for benchmarking performance across user engagement parameters.
