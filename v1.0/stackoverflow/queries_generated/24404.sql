WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        p.OwnerUserId,
        ARRAY_LENGTH(string_to_array(p.Tags, '<>'), 1) AS TagCount,
        COALESCE((SELECT COUNT(DISTINCT c.Id) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM
        Posts p
    WHERE
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - u.CreationDate))) / 3600 AS HoursOnPlatform
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.Reputation
),
PostAnalytics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TagCount,
        ua.UserId,
        ua.Reputation,
        ua.BadgeCount,
        ua.TotalBounty,
        ua.HoursOnPlatform,
        CASE 
            WHEN ua.Reputation > 1000 THEN 'Expert'
            WHEN ua.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
            ELSE 'Beginner'
        END AS UserLevel
    FROM
        RankedPosts rp
    LEFT JOIN
        Users ua ON rp.OwnerUserId = ua.Id
    WHERE
        rp.PostRank < 11 -- Top 10 posts per type
)
SELECT
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.TagCount,
    pa.Reputation,
    pa.UserLevel,
    (CASE
        WHEN pa.TagCount = 0 THEN 'No Tags'
        ELSE 'Has Tags'
    END) AS TagStatus,
    CASE 
        WHEN pa.Score IS NULL THEN 'Unscored'
        WHEN pa.Score >= 100 THEN 'Highly Scored'
        WHEN pa.Score BETWEEN 0 AND 99 THEN 'Moderately Scored'
        ELSE 'Low Scored'
    END AS ScoreCategory
FROM
    PostAnalytics pa
WHERE
    pa.CommentCount > 5 OR pa.TotalBounty > 0
ORDER BY
    pa.Score DESC, pa.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

-- Notes:
-- This SQL retrieves information about the top 10 posts per post type created in the last year.
-- It also includes the user’s reputation and classifies them into expert, intermediate, or beginner.
-- Additionally, it evaluates the tag status and score category for each post. Posts must have more than 5 comments or be associated with a bounty.
