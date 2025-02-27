WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tags edits
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Upvotes,
        rp.Downvotes,
        re.EditDate,
        re.UserDisplayName AS EditorName,
        re.Comment AS EditComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId
    WHERE 
        rp.UserRank <= 5 -- Only top 5 posts per user
)
SELECT 
    c.PostId,
    c.Title,
    c.CreationDate,
    c.Upvotes,
    c.Downvotes,
    COALESCE(c.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(c.EditorName, 'N/A') AS LastEditor,
    COALESCE(c.EditComment, 'No Comments') AS LastEditComment
FROM 
    CombinedData c
WHERE 
    c.Upvotes > c.Downvotes
ORDER BY 
    c.Upvotes DESC
LIMIT 10;

WITH TotalBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tb.BadgeCount
FROM 
    Users u
LEFT JOIN 
    TotalBadges tb ON u.Id = tb.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    COALESCE(tb.BadgeCount, 0) DESC, 
    u.Reputation DESC;
