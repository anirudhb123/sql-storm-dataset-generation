WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Only questions from the last year
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edits for title, body, or tags
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName AS Author,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    COALESCE(pv.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pv.Downvotes, 0) AS TotalDownvotes,
    COALESCE(hd.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(hd.Comment, 'No Comment') AS LastEditComment,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.LastBadgeDate, 'No Badges') AS LastBadgeDate
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostHistoryDetails hd ON rp.PostId = hd.PostId AND hd.EditDate = (
        SELECT MAX(EditDate)
        FROM PostHistoryDetails h
        WHERE h.PostId = rp.PostId
    )
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 5 -- Selecting top 5 questions per user
ORDER BY 
    u.Reputation DESC, rp.CreationDate DESC;
