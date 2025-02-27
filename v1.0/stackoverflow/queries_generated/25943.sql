WITH PopularTags AS (
    SELECT
        UNNEST(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagUsageCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  -- Filtering only Questions
    GROUP BY
        TagName
    ORDER BY
        TagUsageCount DESC
    LIMIT 10  -- Change the limit to get the top N popular tags
),

PostInteraction AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        p.CreationDate,
        pt.Name AS PostTypeName
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.Tags ILIKE ANY (SELECT '%' || TagName || '%' FROM PopularTags)  -- Matching with popular tags
    GROUP BY
        p.Id, pt.Name
    HAVING
        COUNT(c.Id) > 0  -- Only include posts with comments
    ORDER BY
        UpvoteCount DESC  -- Order by highest upvotes
),

UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VotesReceived
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.UserId != u.Id  -- Votes received by posts created by the user
    WHERE
        u.Reputation > 1000  -- Filtering for experienced users
    GROUP BY
        u.Id, u.DisplayName
),

FinalBenchmark AS (
    SELECT
        p.PostId,
        p.Title,
        p.CommentCount,
        p.UpvoteCount,
        p.DownvoteCount,
        u.DisplayName AS CreatorName,
        u.PostsCreated,
        u.VotesReceived
    FROM
        PostInteraction p
    JOIN
        UserEngagement u ON p.Title ILIKE '%' || u.DisplayName || '%'
    ORDER BY
        p.UpvoteCount DESC,  -- Highest upvotes
        u.VotesReceived DESC  -- Highest votes received
)

SELECT
    fb.PostId,
    fb.Title,
    fb.CommentCount,
    fb.UpvoteCount,
    fb.DownvoteCount,
    fb.CreatorName,
    fb.PostsCreated,
    fb.VotesReceived
FROM
    FinalBenchmark fb
LIMIT 50;  -- Change the limit for the number of results you want to retrieve
