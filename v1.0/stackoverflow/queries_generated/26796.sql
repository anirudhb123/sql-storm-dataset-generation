WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        AvgPostScore,
        DENSE_RANK() OVER (ORDER BY TotalVotes DESC) AS Rank
    FROM 
        UserVoteStats
)

SELECT 
    tu.DisplayName,
    tu.TotalVotes,
    tu.UpVotes,
    tu.DownVotes,
    tu.AvgPostScore,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId 
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.DisplayName, tu.TotalVotes, tu.UpVotes, tu.DownVotes, tu.AvgPostScore
ORDER BY 
    tu.Rank;

This query benchmarks string processing by:

1. Aggregating user vote statistics, including total votes, upvotes, downvotes, and average post scores.
2. Identifying the top 10 users based on total votes.
3. Joining to find associated tags for posts created by these top users using string manipulation on the `Tags` column.
4. Grouping the results to present a summary of user activity related to their posts and tags they used.
