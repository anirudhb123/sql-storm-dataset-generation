WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= (NOW() - INTERVAL '1 year') AND
        p.Score > 0
),
TopUserVotes AS (
    SELECT
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
    HAVING
        COUNT(v.Id) > 10
),
PostWithTags AS (
    SELECT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(NULLIF(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'), '{}'::varchar[])) AS t(TagName) ON TRUE
    WHERE
        p.PostTypeId = 1 -- Questions only
    GROUP BY p.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    COALESCE(pt.Tags, 'No Tags') AS Tags,
    tuv.UserId,
    tuv.VoteCount,
    tuv.UpVotes,
    tuv.DownVotes
FROM
    RankedPosts rp
JOIN
    PostWithTags pt ON rp.PostId = pt.PostId
LEFT JOIN
    TopUserVotes tuv ON tuv.UserId = (SELECT u.Id
                                       FROM Users u
                                       WHERE u.Reputation = (SELECT MAX(Reputation)
                                                             FROM Users
                                                             WHERE LastAccessDate >= (NOW() - INTERVAL '1 month'))
                                       LIMIT 1)
WHERE
    rp.Rank <= 3
ORDER BY
    rp.Score DESC,
    rp.ViewCount DESC
LIMIT 10;

### Explanation of the Query:
- **CTE: RankedPosts**: This common table expression (CTE) ranks posts by score and view count, filtering to only include posts created in the last year with a positive score.
  
- **CTE: TopUserVotes**: This CTE aggregates user votes to find users with more than 10 total votes. It counts upvotes and downvotes separately using conditional aggregation.

- **CTE: PostWithTags**: This CTE parses the tags from posts of type "Question" (PostTypeId = 1) and concatenates them into a single string for each post.

- **Main Query**: The main SELECT statement pulls top-ranked questions along with their tags. It uses a subquery to find a user with the highest reputation who has accessed the site in the last month and includes their vote statistics.

- **LEFT JOIN**: This operation ensures that if a post has no associated upvotes or downvotes, it won't exclude the post from the final list.

- **Complex WHERE Clause**: Helps narrow down posts specifically to `PostTypeId = 1` and limits the output to the top 3 ranked posts.

- **Output**: The result is a list of top questions with their associated votes and tags, providing a broad overview of trending topics and user engagement on the platform.
