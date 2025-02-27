WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(vb.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(vb.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        pg.Name AS PostType,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        u.DisplayName
    FROM 
        Posts p
    LEFT JOIN 
        VoteTypes vb ON vb.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTypes pg ON pg.Id = p.PostTypeId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId AND b.Class = 1
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.Rank,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    rp.PostType,
    rp.UserBadge,
    rp.DisplayName
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;

-- Bubble up questions that might have been accepted (answered) but still maintain their original context
WITH QuestionDetails AS (
    SELECT 
        p.Id AS QuestionId,
        p.AcceptedAnswerId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
            ELSE 'No Accepted Answer'
        END AS AcceptanceStatus
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
)
SELECT 
    q.QuestionId,
    q.AcceptanceStatus,
    COALESCE(a.Id, 'NULL') AS AssociatedAnswer,
    COALESCE(a.Title, 'No Answers Yet') AS AnswerTitle
FROM 
    QuestionDetails q
LEFT JOIN 
    Posts a ON a.Id = q.AcceptedAnswerId
WHERE 
    q.AcceptedAnswerId IS NOT NULL
ORDER BY 
    q.QuestionId;

-- Anomalous expiration of badges: Users without badges for more than a year since creation
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    b.Date AS BadgeDate,
    DATEDIFF(NOW(), u.CreationDate) AS DaysSinceCreation,
    CASE WHEN b.Id IS NULL THEN 'No Badge' ELSE b.Name END AS UserBadge
FROM 
    Users u
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Date <= NOW() - INTERVAL '1 year'
WHERE 
    b.Id IS NULL
ORDER BY 
    u.Reputation DESC;

-- Checking for the relation of posts with double-dip open/close actions via history
WITH PostCloseHistory AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS OpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    pch.CloseCount,
    pch.OpenCount,
    CASE 
        WHEN pch.CloseCount > 1 AND pch.OpenCount > 1 THEN 'Double Dip Detected'
        ELSE 'No Double Dip'
    END AS Status
FROM 
    Posts p
JOIN 
    PostCloseHistory pch ON p.Id = pch.PostId
WHERE 
    pch.CloseCount > 0
ORDER BY 
    pch.CloseCount DESC;
