WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount,
            UserId
        FROM Votes
        GROUP BY PostId, UserId
    ) v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
), RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
), PostVotes AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 4 THEN 1 END) AS OffensiveVotes
    FROM Votes
    GROUP BY PostId
), TopRatedPosts AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostVotes v ON p.Id = v.PostId
    WHERE p.Score IS NOT NULL AND p.Score > 0
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    COALESCE(rp.Title, 'No Recent Post') AS RecentPostTitle,
    COALESCE(rp.CreationDate, 'N/A') AS RecentPostDate,
    COALESCE(trp.Score, 0) AS TopScore,
    COALESCE(trp.UpVotes, 0) AS TopPostUpVotes,
    COALESCE(trp.DownVotes, 0) AS TopPostDownVotes
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.RN = 1
LEFT JOIN TopRatedPosts trp ON ua.UserId = trp.Author
WHERE ua.TotalVotes > 0
ORDER BY ua.Reputation DESC, TopScore DESC
LIMIT 50;

This query performs the following actions:
1. **CTE UserActivity** gathers detailed metrics about users' activity with their posts and votes.
2. **CTE RecentPosts** captures the most recent post by each user in the last 30 days.
3. **CTE PostVotes** aggregates the vote counts for each post, counting upvotes, downvotes, and offensive votes.
4. **CTE TopRatedPosts** summarizes information about the highest scoring posts, including vote counts and author.
5. The main query ties all data together, ensuring users are shown their most recent posts and their top-rated posts—all consolidated and sorted by reputational and post metrics. 

The use of outer joins, window functions, CTEs, and aggregated data gives a complex overview suitable for performance benchmarking.
