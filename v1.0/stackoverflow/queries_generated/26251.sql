WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,  -- UpMod
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount  -- DownMod
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1  -- Only Questions
    GROUP BY
        p.Id
), PostAnalytics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.TagCount,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.Score > 0 THEN 'Positive' 
            WHEN rp.Score < 0 THEN 'Negative' 
            ELSE 'Neutral' 
        END AS ScoreCategory,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PopularityRank
    FROM
        RankedPosts rp
), FilteredPosts AS (
    SELECT 
        pa.*,
        COALESCE(SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount  -- Count of badges for the post owners
    FROM 
        PostAnalytics pa
    LEFT JOIN Badges b ON pa.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = b.UserId)
    LEFT JOIN Users u ON pa.PostId = u.Id  -- Use user's Id to match with badges
    GROUP BY 
        pa.PostId, pa.Title, pa.CreationDate, pa.Score, pa.ViewCount, pa.TagCount, pa.CommentCount, pa.UpvoteCount, pa.DownvoteCount
)
SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.TagCount,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.DownvoteCount,
    fp.ScoreCategory,
    fp.PopularityRank,
    fp.BadgeCount
FROM 
    FilteredPosts fp
WHERE
    fp.PopularityRank <= 10  -- Top 10 popular posts based on Score and ViewCount
ORDER BY
    fp.PopularityRank;
