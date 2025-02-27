WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    ) t ON TRUE
    GROUP BY p.Id
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        CommentCount,
        rn,
        Tags,
        CASE 
            WHEN Score >= 10 THEN 'Highly Rated'
            WHEN Score BETWEEN 5 AND 9 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS ScoreCategory
    FROM RankedPosts
    WHERE rn <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.ScoreCategory,
    COALESCE(NULLIF(fp.Tags[1], ''), 'No Tags') AS PrimaryTag,
    COALESCE((
        SELECT ARRAY_AGG(DISTINCT bh.Name)
        FROM Badges b
        JOIN Users u ON b.UserId = u.Id
        WHERE u.Id = fp.PostId
    ), '{}') AS UserBadges
FROM FilteredPosts fp
LEFT JOIN Votes v ON fp.PostId = v.PostId
WHERE v.VoteTypeId = 2 -- Upvote
AND EXISTS (
    SELECT 1
    FROM PostHistory ph
    WHERE ph.PostId = fp.PostId 
      AND ph.PostHistoryTypeId IN (10, 11, 12) -- Check for closed/open actions 
      AND ph.CreationDate >= now() - interval '1 year'
)
ORDER BY fp.Score DESC, fp.CreationDate ASC
LIMIT 100;
