WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
TopAnswers AS (
    SELECT
        p.Id AS AnswerId,
        p.Title AS AnswerTitle,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        p.Score,
        p.CreationDate AS AnswerDate,
        RANK() OVER (PARTITION BY p.ParentId ORDER BY p.Score DESC) AS AnswerRank
    FROM 
        Posts p
    JOIN 
        RankedPosts r ON p.Id = r.PostId AND r.PostTypeId = 2
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        r.CommentCount > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate,
        ct.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ta.AnswerId,
    ta.AnswerTitle,
    ta.OwnerDisplayName,
    ta.Score AS AnswerScore,
    cp.ClosedDate,
    cp.CloseReason,
    ua.DisplayName AS UserDisplayName,
    ua.Upvotes,
    ua.Downvotes,
    ua.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopAnswers ta ON rp.PostId = ta.ParentId AND ta.AnswerRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserActivity ua ON rp.PostId = (
        SELECT 
            p.Id
        FROM 
            Posts p
        WHERE 
            p.OwnerUserId = ua.UserId
        LIMIT 1
    )
WHERE 
    rp.Score > 10
    AND rp.ScoreRank <= 10
    AND (cp.ClosedDate IS NOT NULL OR ta.AnswerId IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
