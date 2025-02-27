WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
PostWithLinks AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Rank,
        pl.RelatedPostId,
        CASE 
            WHEN pl.LinkTypeId = 1 THEN 'Linked'
            WHEN pl.LinkTypeId = 3 THEN 'Duplicate'
            ELSE 'Other'
        END AS LinkType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostLinks pl ON rp.PostId = pl.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        pwl.PostId,
        pwl.Title,
        pwl.OwnerDisplayName,
        pwl.CreationDate,
        pwl.ViewCount,
        pwl.Rank,
        pwl.RelatedPostId,
        pwl.LinkType,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        PostWithLinks pwl
    LEFT JOIN 
        UserBadges ub ON pwl.OwnerDisplayName = ub.UserId
)
SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.CreationDate,
    f.ViewCount,
    f.Rank,
    f.RelatedPostId,
    f.LinkType,
    COALESCE(f.BadgeCount, 0) AS BadgeCount,
    COALESCE(f.BadgeNames, 'None') AS BadgeNames,
    CASE 
        WHEN f.HasAcceptedAnswer = 1 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptedStatus
FROM 
    FinalResults f
WHERE 
    f.Rank <= 5 -- Top 5 questions per user
ORDER BY 
    f.Rank, f.ViewCount DESC;

-- Considerations:
-- This query utilizes multiple CTEs to gather data regarding posts, links, user badges,
// and creates a final dataset that provides a comprehensive overview of the top
// questions, including their status, along with badge counts for authors.
-- Edge cases are handled, ensuring users without badges show 'None' and counts default to zero.
-- The approach leverages window functions for ranking and other aggregates to dissect the data based on nuanced relationships.
