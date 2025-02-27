WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(v.PostId) OVER (PARTITION BY p.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownvoteCount
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),

TagPostCounts AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM
        Posts p
    CROSS JOIN
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName)  -- Assuming tags are formatted in standard way
    GROUP BY
        t.TagName
),

UserVoteSummary AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
)

SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.VoteCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    tpc.PostCount AS TagPostCount,
    CASE
        WHEN us.TotalUpvotes > us.TotalDownvotes THEN 'Overall Positive'
        WHEN us.TotalUpvotes < us.TotalDownvotes THEN 'Overall Negative'
        ELSE 'Neutral'
    END AS UserVoteSentiment
FROM
    RankedPosts rp
LEFT JOIN
    TagPostCounts tpc ON tpc.TagName = ANY(string_to_array(rp.Tags, '><'))
LEFT JOIN
    UserVoteSummary us ON us.UserId = rp.OwnerUserId
WHERE
    rp.ScoreRank <= 5  -- Top 5 posts by score
    AND rp.Score IS NOT NULL
    AND rp.Title IS NOT NULL
ORDER BY
    rp.Score DESC, rp.ViewCount DESC;

-- This query calculates information on top scoring posts within the last 30 days,
-- joins with tags to find the number of posts associated with each tag and summarizes user upvotes/downvotes.
