WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostsWithBadges AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        CASE 
            WHEN ub.BadgeCount IS NULL THEN 'No badges'
            ELSE 'Has badges'
        END AS UserBadges,
        ub.Reputation,
        ub.TotalBountyAmount,
        CASE 
            WHEN rp.Score > 5 THEN 'High Score' 
            ELSE 'Low Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.Score,
    pwb.ViewCount,
    pwb.AnswerCount,
    pwb.CommentCount,
    pwb.UserBadges,
    pwb.Reputation,
    pwb.TotalBountyAmount,
    CASE 
        WHEN pwb.Reputation > 1000 THEN 'Veteran' 
        WHEN pwb.Reputation BETWEEN 500 AND 1000 THEN 'Experienced' 
        ELSE 'Novice' 
    END AS UserExperience,
    CASE 
        WHEN pwb.TotalBountyAmount IS NULL THEN 'No Bounties'
        ELSE 'Bounty Offered'
    END AS BountyStatus
FROM 
    PostsWithBadges pwb
WHERE 
    pwb.UserBadges = 'Has badges' 
    AND pwb.ScoreCategory = 'High Score'
ORDER BY 
    pwb.Reputation DESC NULLS LAST, 
    pwb.CreationDate DESC;

This query performs several tasks:

1. It creates a Common Table Expression (`RankedPosts`) to rank posts made by users in the last year by their creation date.
2. It creates another CTE (`UserReputation`) to summarize user reputations and count badges.
3. It combines these two CTEs into a new CTE (`PostsWithBadges`) to produce a final set of posts, adding user badge information, user experience categorization, and bounty status.
4. Finally, it filters the results to only include users who have badges and posts with high scores then orders by user reputation and creation date. 

The query makes use of `ROW_NUMBER`, `COALESCE`, string expressions, NULL logic, joins, and complex predicates.
