
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts
),
UserStats AS (
    SELECT
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        COUNT(CASE WHEN Reputation > 1000 THEN 1 END) AS UsersWithHighReputation
    FROM 
        Users
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN VoteTypeId = 6 THEN 1 ELSE 0 END) AS TotalCloseVotes
    FROM 
        Votes
)

SELECT
    ps.TotalPosts,
    ps.UniquePostOwners,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalViews,
    ps.TotalScore,
    us.TotalUsers,
    us.TotalReputation,
    us.UsersWithHighReputation,
    vs.TotalVotes,
    vs.TotalUpVotes,
    vs.TotalDownVotes,
    vs.TotalCloseVotes
FROM 
    PostStats ps,
    UserStats us,
    VoteStats vs;
