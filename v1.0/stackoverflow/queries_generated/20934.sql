WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > now() - interval '30 days'
    GROUP BY 
        p.Id
    HAVING 
        COUNT(DISTINCT v.Id) > 0
),

TopTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),

PostsWithTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.UpVotes,
        rp.DownVotes,
        tt.TagName
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Tags tt ON p.Tags LIKE '%' || tt.TagName || '%'
)

SELECT 
    pwt.PostId,
    pwt.Title,
    pwt.CreationDate,
    pwt.UpVotes,
    pwt.DownVotes,
    tt.TagName,
    CASE 
        WHEN pwt.UpVotes > pwt.DownVotes THEN 'Positive'
        WHEN pwt.UpVotes < pwt.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    (SELECT STRING_AGG(DISTINCT b.Name, ', ') 
     FROM Badges b 
     WHERE b.UserId = p.OwnerUserId) AS UserBadges
FROM 
    PostsWithTags pwt
LEFT JOIN 
    Users u ON u.Id = pwt.OwnerUserId
WHERE 
    pwt.UpVotes - pwt.DownVotes > 5 
    OR pwt.CreationDate > now() - interval '7 days'
ORDER BY 
    pwt.CreationDate DESC;

-- UNION with a summary of top tags
UNION ALL 

SELECT
    NULL AS PostId,
    'Top Tags Summary' AS Title,
    NULL AS CreationDate,
    NULL AS UpVotes,
    NULL AS DownVotes,
    tt.TagName,
    NULL AS Sentiment,
    NULL AS UserBadges
FROM 
    TopTags tt;

-- Total vote counts as a CTE for final aggregation (additional layer)
WITH TotalVotes AS (
    SELECT 
        COUNT(*) AS TotalUpVotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Votes
)

SELECT 
    (SELECT TotalUpVotes FROM TotalVotes) AS TotalPositiveVotes,
    (SELECT TotalDownVotes FROM TotalVotes) AS TotalNegativeVotes;

In this SQL query:
- The `RecentPosts` CTE summarizes posts from the last 30 days with vote counts.
- The `TopTags` CTE identifies the ten most used tags associated with posts.
- The `PostsWithTags` CTE constructs a detailed view of recent posts along with their associated tags.
- The main SELECT statement evaluates the sentiment based on vote counts and aggregates user badges.
- A UNION ALL incorporates a summary of the top tags used in posts.
- Finally, a CTE called `TotalVotes` calculates the overall upvote and downvote counts across the entire Vote table.
