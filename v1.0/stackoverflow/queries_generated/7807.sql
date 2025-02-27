WITH UserAnalysis AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        AVG(DATEDIFF(COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP), p.CreationDate)) AS AvgPostAgeInDays
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        Upvotes,
        Downvotes,
        AvgPostAgeInDays,
        RANK() OVER (ORDER BY Upvotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY DOWNvotes DESC) AS DownvoteRank
    FROM 
        UserAnalysis
    WHERE 
        PostCount > 0
)

SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    t.PostCount,
    t.CommentCount,
    t.Upvotes,
    t.Downvotes,
    t.AvgPostAgeInDays,
    p.Title AS MostRecentPostTitle,
    p.CreationDate AS MostRecentPostDate
FROM 
    TopUsers t
JOIN 
    Posts p ON t.UserId = p.OwnerUserId
WHERE 
    p.CreationDate = (SELECT MAX(CreationDate) FROM Posts WHERE OwnerUserId = t.UserId)
ORDER BY 
    t.UpvoteRank, t.DownvoteRank
LIMIT 10;
