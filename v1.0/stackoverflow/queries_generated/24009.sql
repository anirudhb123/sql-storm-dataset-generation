WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG( DISTINCT pht.Name, ', ') AS ChangeTypes,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
TopPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rnk
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.TotalPosts,
    uvs.TotalQuestions,
    uvs.TotalAnswers,
    ph.ChangeTypes,
    ph.HistoryCount,
    ph.LastChangeDate,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount
FROM UserVoteStats uvs
LEFT JOIN PostHistoryDetails ph ON uvs.UserId = ph.PostId
JOIN TopPosts tp ON tp.PostId = ph.PostId 
WHERE tp.rnk <= 5
ORDER BY uvs.UpVotes DESC, uvs.DownVotes ASC, uvs.TotalPosts DESC;

This query compiles the performance metrics of users with a reputation greater than 100 who have actively voted on posts, while also displaying details of the top posts created within the last year that have the highest scores and views. 

1. The **UserVoteStats** CTE calculates the upvote and downvote statistics for users, along with their total number of posts and specific counts for questions and answers.
2. The **PostHistoryDetails** CTE aggregates the history of post changes, counting distinct changes and capturing the maximum (latest) change date for each post.
3. The **TopPosts** CTE retrieves the top five posts by score and view count, partitioned by post type.
4. The final SELECT combines this data to show users’ voting behaviors alongside the detailed history of the top posts, ordered by their upvotes, downvotes, and total posts. 

It incorporates outer joins, string aggregation, window functions, and complex predicates to paint a detailed picture of post engagement and voting trends in a particular timeframe.
