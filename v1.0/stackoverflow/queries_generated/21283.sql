WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.Rank,
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        CASE 
            WHEN rp.ViewCount = 0 THEN NULL 
            ELSE ROUND((rp.Score::decimal / NULLIF(rp.ViewCount, 0)) * 100, 2)
        END AS ScorePerView
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        b.UserId
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.NetVotes,
    fp.ScorePerView,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.PostId IN (SELECT p.OwnerUserId FROM Posts p WHERE fp.PostId = p.Id)
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM PostHistory ph 
        WHERE ph.PostId = fp.PostId 
          AND ph.PostHistoryTypeId IN (10, 20)
    )
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
LIMIT 100;

-- Explanation of unusual SQL constructs:
-- The initial CTE (Common Table Expression) `RankedPosts` calculates rankings and aggregates vote counts while one level of nested LEFT JOINs is included to ensure we preserve all relevant posts even if they don't have comments or votes.
-- The second CTE `FilteredPosts` computes net votes and introduces a score view ratio that uses NULL logic to prevent division by zero.
-- The `UserBadges` CTE aggregates user badges earned in the last 30 days, using `STRING_AGG` to concatenate badge names.
-- The main query joins the filtered posts with user badges and excludes posts from history that had been closed or protected, ensuring only active discussions shown.
-- The final result is ordered by the score and visual engagement, maintaining a limit of 100 to streamline outputs.
