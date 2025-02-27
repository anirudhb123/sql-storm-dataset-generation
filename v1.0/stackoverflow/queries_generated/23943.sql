WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
PopularQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.UserReputation,
        CASE 
            WHEN rp.UserReputation >= 1000 THEN 'Highly Recognized'
            WHEN rp.UserReputation >= 500 THEN 'Moderately Recognized'
            ELSE 'New User'
        END AS UserRecognitionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
UserWithBadges AS (
    SELECT 
        DISTINCT u.Id,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
QuestionStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty related votes
    WHERE 
        p.PostTypeId = 1   -- Only questions
    GROUP BY 
        p.Id
)

SELECT 
    pq.PostId,
    pq.Title,
    pq.ViewCount,
    pq.UserReputation,
    pq.UserRecognitionLevel,
    us.DisplayName AS BadgeHolder,
    us.BadgeCount,
    qs.CommentCount,
    qs.TotalBounty,
    CASE 
        WHEN qs.CommentCount = 0 THEN 'No comments yet'
        WHEN qs.CommentCount > 10 THEN 'Popular with many comments'
        ELSE 'Few comments'
    END AS CommentStatus
FROM 
    PopularQuestions pq
LEFT JOIN 
    UserWithBadges us ON pq.UserReputation > us.BadgeCount * 100  -- Arbitrarily relates reputation to badge count
LEFT JOIN 
    QuestionStatistics qs ON pq.PostId = qs.PostId
WHERE 
    pq.UserReputation IS NOT NULL 
ORDER BY 
    pq.ViewCount DESC, 
    pq.PostId ASC
LIMIT 50;

-- Add an awkward twist with a bizarre sort order that combines ViewCount, which typically is a measure of popularity,
-- and PostId, which is a primary key. This is a bit unusual but makes for interesting sorting logic.
