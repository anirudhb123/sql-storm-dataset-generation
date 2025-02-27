WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  -- Only Questions
      AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only posts from the last year
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        TRIM(BOTH '>' FROM UNNEST(string_to_array(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '>'))) ) AS IndividualTag
    FROM RankedPosts rp
    WHERE rp.TagRank <= 5  -- Keep only the top 5 posts per tag
),

TagAggregation AS (
    SELECT 
        IndividualTag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVoteCount) AS TotalUpVotes
    FROM FilteredPosts
    GROUP BY IndividualTag
)

SELECT 
    ta.IndividualTag,
    ta.PostCount,
    ta.TotalViews,
    ta.TotalComments,
    ta.TotalUpVotes,
    (ta.TotalViews / NULLIF(ta.PostCount, 0)) AS AvgViewsPerPost,
    (ta.TotalComments / NULLIF(ta.PostCount, 0)) AS AvgCommentsPerPost,
    (ta.TotalUpVotes / NULLIF(ta.PostCount, 0)) AS AvgUpVotesPerPost
FROM TagAggregation ta
ORDER BY AvgViewsPerPost DESC, AvgCommentsPerPost DESC, AvgUpVotesPerPost DESC
LIMIT 10;  -- Output top 10 tags by average views
