WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Body,
        p.Tags,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tag AS Tags ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts from the last 30 days
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
HighlightedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Body,
        rp.CreationDate,
        rp.VoteCount,
        rp.CommentCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = ub.UserId)
    WHERE 
        rp.PostRank = 1  -- Get only the last question for each tag
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.OwnerDisplayName,
    hp.Body,
    hp.CreationDate,
    hp.VoteCount,
    hp.CommentCount,
    hp.BadgeNames
FROM 
    HighlightedPosts hp
ORDER BY 
    hp.VoteCount DESC, hp.CreateDate DESC
LIMIT 10;
