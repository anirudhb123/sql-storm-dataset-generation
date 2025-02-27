WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
), 
FinalStats AS (
    SELECT 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate AS UserCreationDate, 
        uvs.UpVotes, 
        uvs.DownVotes, 
        ps.PostId, 
        ps.CommentCount, 
        ps.TotalBounty, 
        ps.LastPostDate,
        CASE 
            WHEN ps.RankByComments <= 5 THEN 'Top Contributor'
            ELSE 'Regular Contributor'
        END AS ContributorLevel
    FROM 
        Users u
    JOIN 
        UserVoteStats uvs ON u.Id = uvs.UserId
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    fs.DisplayName,
    fs.Reputation,
    fs.UserCreationDate,
    fs.UpVotes,
    fs.DownVotes,
    fs.PostId,
    fs.CommentCount,
    fs.TotalBounty,
    fs.LastPostDate,
    fs.ContributorLevel
FROM 
    FinalStats fs
WHERE 
    fs.Reputation > (SELECT AVG(Reputation) FROM Users) 
AND 
    fs.LastPostDate > NOW() - INTERVAL '1 year' 
ORDER BY 
    fs.TotalBounty DESC NULLS LAST;

### Explanation:
1. **Common Table Expressions (CTEs)**: The query uses three CTEs: 
   - **UserVoteStats** to calculate upvotes and downvotes per user using conditional aggregation.
   - **PostStats** to gather statistics for each post, including the number of comments and total bounty, while also ranking posts by the number of comments for each user.
   - **FinalStats** which joins the previous CTEs and classifies users based on their contribution levels.

2. **Outer Joins**: The left joins ensure that users without votes or posts are still considered in the results.

3. **Correlated Subquery**: The WHERE clause filters users whose reputation is above average, using a subquery to get the average.

4. **Window Functions**: ROW_NUMBER is used to enumerate posts per user based on their comment count.

5. **Aggregation and Grouping**: Various counts and sums are calculated within the CTEs.

6. **String and NULL Logic**: The CASE statement categorizes contributor levels while the NULLS LAST handles sorting appropriately.

7. **Timestamp Filtering**: Filters users who have posted within the last year. 

8. **Ordering**: The final result set is ordered by total bounty, placing the users’ most impactful activities upfront.

This query integrates multiple SQL features, ensuring effective performance benchmarking while demonstrating the flexibility and power of SQL in complex data manipulations.
