WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
TopViewedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= DATEADD(month, -6, GETDATE())
),
PostCommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments,
        SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(CONVERT(varchar, ph.CreationDate, 120), ', ') AS ChangeDates
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        ph.PostId, 
        ph.PostHistoryTypeId
)
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    pcs.CommentCount,
    pcs.PositiveComments,
    pcs.NegativeComments,
    phs.ChangeCount,
    phs.ChangeDates,
    p.ViewCount,
    p.Score
FROM 
    TopViewedPosts p
JOIN 
    ActiveUsers u ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostCommentStats pcs ON pcs.PostId = p.PostId
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId = p.PostId
WHERE 
    u.UserRank <= 10 -- Limit to top 10 active users
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
This SQL query performs a detailed analysis of posts created within the last year. It ranks users by their reputation, collects statistics about comments, and summarizes changes from the post history, producing an insightful overview of popular posts alongside their engaging authors.
