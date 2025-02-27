-- Performance Benchmarking Query for StackOverflow Schema

-- 1. Retrieve the total number of posts and their average view count
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViewCount
    FROM 
        Posts
),
-- 2. Calculate the total number of users and their average reputation
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM 
        Users
),
-- 3. Get the number of votes and average votes per post
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        AVG(VoteCount) AS AverageVotesPerPost
    FROM (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS PostVoteCounts
)
-- 4. Combine the results into a single output
SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT AverageViewCount FROM PostStats) AS AverageViewCount,
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT AverageReputation FROM UserStats) AS AverageReputation,
    (SELECT TotalVotes FROM VoteStats) AS TotalVotes,
    (SELECT AverageVotesPerPost FROM VoteStats) AS AverageVotesPerPost;
