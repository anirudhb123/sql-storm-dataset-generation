WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.CommentCount,
        ua.UpVoteCount,
        ua.DownVoteCount,
        ua.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ua.Reputation DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.Reputation > 1000 -- Filter for active users
)

SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.PostCount,
    tu.CommentCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    tu.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerDisplayName AND rp.RecentRank = 1
ORDER BY 
    tu.Rank
FETCH FIRST 10 ROWS ONLY; -- Limit to top 10 users
This query consists of three common table expressions (CTEs):
1. **UserActivity**: Aggregates user data to calculate the count of posts, comments, and votes for each user.
2. **RecentPosts**: Selects the most recent questions for each user.
3. **TopUsers**: Filters users with a reputation higher than 1000 and ranks them based on their reputation.

Finally, the main query combines these CTEs to produce a comprehensive list of the top users, their activity counts, and their most recent post details, limited to the top 10 results.
