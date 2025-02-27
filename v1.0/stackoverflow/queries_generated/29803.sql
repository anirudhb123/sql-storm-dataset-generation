WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), '1900-01-01') AS LastVoteDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2022-01-01' -- Filtering posts created in 2022 onwards
      AND p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.Tags
),
TaggedPosts AS (
    SELECT 
        PostId,
        unnest(string_to_array(Tags, '><')) AS Tag
    FROM RankedPosts
),
UserTagCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT tp.Tag) AS UniqueTags,
        p.CommentCount,
        p.LastVoteDate
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN TaggedPosts tp ON tp.PostId = p.Id
    WHERE p.CreationDate >= '2022-01-01'
    GROUP BY u.Id, u.DisplayName, p.CommentCount, p.LastVoteDate
)
SELECT 
    utc.UserId,
    utc.DisplayName,
    utc.UniqueTags,
    utc.CommentCount,
    utc.LastVoteDate,
    ROW_NUMBER() OVER (ORDER BY utc.UniqueTags DESC) AS Rank
FROM UserTagCounts utc
WHERE utc.UniqueTags >= 5  -- Users with at least 5 unique tags
ORDER BY utc.UniqueTags DESC, utc.CommentCount DESC;
