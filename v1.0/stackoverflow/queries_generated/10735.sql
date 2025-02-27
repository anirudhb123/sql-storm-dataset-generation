-- Performance Benchmarking Query

-- This query benchmarks the performance of various operations on the Posts, Users, and Votes tables.
-- It retrieves the number of posts, users, and votes, as well as the average score of posts for active users.
-- The query will also provide join performance metrics by fetching related data from these tables.

WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalPostOwners
    FROM 
        Posts
),

UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM 
        Users
),

VoteCounts AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT PostId) AS VotedPosts,
        AVG(VoteTypeId) AS AverageVoteType
    FROM 
        Votes
)

SELECT 
    pc.TotalPosts,
    pc.TotalPostOwners,
    uc.TotalUsers,
    uc.AverageReputation,
    vc.TotalVotes,
    vc.VotedPosts,
    vc.AverageVoteType
FROM 
    PostCounts pc,
    UserCounts uc,
    VoteCounts vc;

