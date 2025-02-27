WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- only questions
),
PopularTags AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagPopularity
    FROM Posts
    WHERE PostTypeId = 1 -- only questions
    GROUP BY TagName
),
TopTags AS (
    SELECT
        TagName,
        TagPopularity,
        ROW_NUMBER() OVER (ORDER BY TagPopularity DESC) AS TagRank
    FROM PopularTags
)

SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Author,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    tt.TagName,
    tt.TagPopularity
FROM RankedPosts rp
JOIN (
    SELECT
        tt.TagName,
        tt.TagPopularity,
        ROW_NUMBER() OVER (PARTITION BY rp.Rank ORDER BY tt.TagPopularity DESC) AS RankedTags
    FROM TopTags tt
) tt ON tt.RankedTags <= 3
WHERE rp.Rank <= 10
ORDER BY rp.Rank, tt.TagPopularity DESC;
