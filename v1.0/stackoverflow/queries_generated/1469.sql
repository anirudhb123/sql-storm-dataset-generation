WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Votes WHERE UserId = Users.Id AND VoteTypeId = 2) AS UpVotesByUser,
        (SELECT COUNT(*) FROM Votes WHERE UserId = Users.Id AND VoteTypeId = 3) AS DownVotesByUser
    FROM 
        Users
),

PostsOverview AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE((SELECT COUNT(*) FROM Comments WHERE PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as UserPostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    r.TotalPosts,
    p.Title,
    p.CreationDate,
    p.Score,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    t.Tags,
    p.UserPostRank,
    CASE 
        WHEN p.Score > 10 THEN 'High Score'
        WHEN p.Score BETWEEN 1 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    UserReputation r
JOIN 
    PostsOverview p ON p.PostId IN (SELECT p.Id FROM Posts p)
LEFT JOIN 
    PostTags t ON t.PostId = p.PostId
JOIN 
    Users u ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation > 100 AND 
    p.UserPostRank <= 5
ORDER BY 
    u.Reputation DESC, 
    p.CreationDate DESC
LIMIT 100
OFFSET 0;
