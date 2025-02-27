WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        COUNT(DISTINCT CASE WHEN CreationDate < NOW() - INTERVAL '1 year' THEN Id END) AS YearOldPosts,
        COUNT(DISTINCT CASE WHEN CreationDate >= NOW() - INTERVAL '1 year' THEN Id END) AS RecentPosts
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Id, Reputation
),
PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.PostTypeId,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(Votes.Id) FILTER (WHERE VoteTypeId = 2) AS Upvotes,
        COUNT(Votes.Id) FILTER (WHERE VoteTypeId = 3) AS Downvotes,
        Posts.Score,
        (CASE 
            WHEN Posts.Body IS NULL THEN 0
            ELSE LENGTH(Posts.Body) - LENGTH(REPLACE(Posts.Body, ' ', '')) + 1
        END) AS WordCount,
        ROW_NUMBER() OVER (PARTITION BY Posts.OwnerUserId ORDER BY Posts.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Comments.PostId = Posts.Id
    LEFT JOIN 
        Votes ON Votes.PostId = Posts.Id
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        Posts.Id, Posts.PostTypeId, Posts.Score, Posts.Body
),
TopUserStats AS (
    SELECT 
        u.DisplayName,
        ur.Reputation,
        p.CommentCount,
        p.Upvotes,
        p.Downvotes,
        p.WordCount,
        CASE 
            WHEN ur.YearOldPosts > 5 THEN 'Veteran'
            WHEN ur.Reputation > 1000 THEN 'Influencer'
            ELSE 'Newcomer'
        END AS UserCategory
    FROM 
        UserReputation ur
    JOIN 
        PostStats p ON ur.Id = p.PostId
    JOIN 
        Users u ON ur.Id = u.Id
    WHERE 
        ur.Reputation > 0
),
DistinctTags AS (
    SELECT DISTINCT 
        UNNEST(string_to_array(Tags, '> <')) AS TagName
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
),
HighlyRatedPosts AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    JOIN 
        DistinctTags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        ps.Score > 10
    GROUP BY 
        p.Title, p.Score, p.ViewCount, p.CreationDate
    HAVING 
        COUNT(DISTINCT t.TagName) >= 3 AND 
        p.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    t.UserCategory,
    h.Title,
    h.Score,
    h.TagCount
FROM 
    TopUserStats t
LEFT JOIN 
    HighlyRatedPosts h ON h.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
WHERE 
    t.UserCategory = 'Influencer' 
ORDER BY 
    u.Reputation DESC, h.Score DESC 
LIMIT 10;
