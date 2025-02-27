
WITH VoteCounts AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(Votes.Id) AS TotalVotes,
        FORMAT(Votes.CreationDate, 'yyyy-MM') AS VoteMonth
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, FORMAT(Votes.CreationDate, 'yyyy-MM')
),
AvgVotePerPost AS (
    SELECT 
        VoteMonth,
        AVG(TotalVotes) AS AvgVotes
    FROM 
        VoteCounts
    GROUP BY 
        VoteMonth
)
SELECT 
    VoteMonth,
    AvgVotes
FROM 
    AvgVotePerPost
ORDER BY 
    VoteMonth DESC;
