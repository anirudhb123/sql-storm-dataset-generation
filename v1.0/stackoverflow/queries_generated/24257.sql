WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 5
),
ReputationBreakdown AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 10000 THEN 'High'
            WHEN u.Reputation BETWEEN 1000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalUpVotes - us.TotalDownVotes AS NetVotes,
    COALESCE(pb.TagPostCount, 0) AS PopularTagCount,
    rb.ReputationLevel,
    (SELECT 
        COUNT(*) 
     FROM 
        PostHistory ph 
     WHERE 
        ph.UserId = us.UserId AND ph.CreationDate > NOW() - INTERVAL '1 MONTH') AS RecentHistoryCount
FROM 
    UserStats us
LEFT JOIN 
    PopularTags pb ON us.TotalPosts > pb.TagPostCount
JOIN 
    ReputationBreakdown rb ON us.UserId = rb.UserId
WHERE 
    us.TotalPosts > 0 -- Exclude users with no posts
    AND (rb.ReputationLevel = 'High' OR us.TotalUpVotes > 100) -- Focus on high rep or active users
ORDER BY 
    NetVotes DESC,
    us.TotalBadges DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

This SQL query performs the following tasks:
- It aggregates statistics about users, including their total upvotes, downvotes, total badges, and total posts in a CTE called `UserStats`.
- It identifies the most popular tags and their corresponding post counts in a second CTE called `PopularTags`.
- The third CTE, `ReputationBreakdown`, categorizes users into different reputation levels based on their reputation scores.
- Finally, the main query selects users who have made at least one post, calculates their net votes, and includes a correlated subquery to count their post history actions in the last month.
- The query filters users based on their reputation level or activity and sorts the results, fetching a specific range of users while considering complex criteria.
