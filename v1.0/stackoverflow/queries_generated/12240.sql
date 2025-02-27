-- Performance Benchmarking SQL Query

-- Query to benchmark the average number of votes received by posts over time
WITH VoteCounts AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(Votes.Id) AS TotalVotes,
        DATE_TRUNC('month', Votes.CreationDate) AS VoteMonth
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, VoteMonth
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

-- Query to benchmark the average time taken from post creation to acceptance of answers
WITH AnswerAcceptance AS (
    SELECT 
        Posts.Id AS QuestionId,
        COALESCE(MIN(Posts2.CreationDate) - Posts.CreationDate, INTERVAL '0 seconds') AS TimeToAcceptance
    FROM 
        Posts
    LEFT JOIN 
        Posts AS Posts2 ON Posts.Id = Posts2.AcceptedAnswerId
    WHERE 
        Posts.PostTypeId = 1 -- Only Questions
    GROUP BY 
        Posts.Id
)
SELECT 
    AVG(EXTRACT(EPOCH FROM TimeToAcceptance)) AS AvgTimeToAcceptanceInSeconds
FROM 
    AnswerAcceptance;

-- Query to benchmark the number of active users (users who have voted or commented) per month
WITH ActiveUsers AS (
    SELECT DISTINCT 
        UserId, 
        DATE_TRUNC('month', CreationDate) AS ActiveMonth
    FROM 
        Votes
    UNION
    SELECT DISTINCT 
        UserId, 
        DATE_TRUNC('month', CreationDate) AS ActiveMonth
    FROM 
        Comments
)
SELECT 
    ActiveMonth,
    COUNT(UserId) AS ActiveUserCount
FROM 
    ActiveUsers
GROUP BY 
    ActiveMonth
ORDER BY 
    ActiveMonth DESC;
