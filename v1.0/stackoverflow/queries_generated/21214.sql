WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) OVER (PARTITION BY p.Id) AS TotalBountyAmount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty Start or Bounty Close
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerUserId,
        rp.Rank,
        rp.CommentCount,
        rp.TotalBountyAmount,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN rp.Score > 100 THEN 'Highly Upvoted'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Upvoted'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE rp.Rank <= 10
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date > NOW() - INTERVAL '6 months'
    GROUP BY b.UserId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.TotalBountyAmount,
    fp.ScoreCategory,
    rb.BadgeCount,
    COALESCE(rb.BadgeNames, 'No Badges') AS BadgeNames
FROM FilteredPosts fp
LEFT JOIN RecentBadges rb ON fp.OwnerUserId = rb.UserId
ORDER BY 
    CASE 
        WHEN fp.ScoreCategory = 'Highly Upvoted' THEN 1
        WHEN fp.ScoreCategory = 'Moderately Upvoted' THEN 2
        ELSE 3
    END,
    fp.ViewCount DESC,
    fp.CreationDate DESC;
This SQL query performs an elaborate selection and ranking of posts within the last year while considering related metadata such as the number of comments, total bounty amounts, and user information. It employs common table expressions (CTEs) to facilitate the organization of data and uses window functions for ranking and counting. Additionally, it categorizes posts based on scores and joins information about user badges for a richer data output.
