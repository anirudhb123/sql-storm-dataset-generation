WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Counting only Upvotes and Downvotes
    WHERE
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY
        p.Id, p.Title, p.Tags, p.CreationDate
),
TagStatistics AS (
    SELECT
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TotalPosts
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Only Questions
    GROUP BY
        unnest(string_to_array(Tags, ','))
),
TopTags AS (
    SELECT 
        TagName,
        TotalPosts,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    CASE 
        WHEN tt.TagRank IS NOT NULL THEN 'Popular Tag'
        ELSE 'Regular'
    END AS TagType
FROM
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TagName = ANY (string_to_array(rp.Tags, ','))
WHERE
    rp.Rank = 1 -- Getting only the top-ranked posts in case of ties
ORDER BY
    rp.CommentCount DESC, rp.VoteCount DESC
LIMIT 50; -- Limit for performance benchmarking
