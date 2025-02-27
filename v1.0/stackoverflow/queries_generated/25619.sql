WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(co.PostId) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN Comments co ON p.Id = co.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod
    WHERE
        p.PostTypeId = 1 -- Questions only
    GROUP BY
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
AggregatedTags AS (
    SELECT
        unnest(string_to_array(Tags, '<>')) AS Tag,
        COUNT(*) AS TagFrequency
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Questions only
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        TagFrequency,
        ROW_NUMBER() OVER (ORDER BY TagFrequency DESC) AS TagRank
    FROM
        AggregatedTags
   WHERE
        Tag IS NOT NULL
),
UserContributions AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(co.Score) AS TotalCommentVotes,
        SUM(v.BountyAmount) AS TotalBounties
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments co ON p.Id = co.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
BenchmarkResults AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        rp.VoteCount,
        tt.Tag AS TopTag,
        uc.DisplayName AS TopContributor
    FROM
        RankedPosts rp
    JOIN TopTags tt ON tt.Tag = ANY(string_to_array(rp.Tags, '<>'))
    JOIN UserContributions uc ON uc.TotalPosts = (SELECT MAX(TotalPosts) FROM UserContributions)
)
SELECT
    PostId,
    Title,
    Body,
    Tags,
    CreationDate,
    CommentCount,
    VoteCount,
    TopTag,
    TopContributor
FROM
    BenchmarkResults
ORDER BY
    CreationDate DESC
LIMIT 10;
