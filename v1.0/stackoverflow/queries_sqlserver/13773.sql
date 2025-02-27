
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        COUNT(*) AS TotalQuestions,
        COUNT(*) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts
),
UserStats AS (
    SELECT
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        COUNT(*) AS UsersWithHighReputation
    FROM 
        Users 
    WHERE Reputation > 1000
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
