WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS BodyPreview
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        pr.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes pr ON ph.Comment::int = pr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Indicates post was closed
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Only users with more than 5 posts
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(LENGTH(c.Text)) AS AvgCommentLength
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CombinedResults AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COALESCE(c.TotalComments, 0) AS TotalComments,
        COALESCE(c.AvgCommentLength, 0) AS AvgCommentLength,
        ARRAY_AGG(DISTINCT pht.CloseReason) AS CloseReasons
    FROM 
        RankedPosts p
    LEFT JOIN 
        CommentStats c ON p.PostId = c.PostId
    LEFT JOIN 
        ClosedPosts ph ON p.PostId = ph.PostId
    WHERE 
        p.PostRank <= 3 -- Top 3 posts per user
    GROUP BY 
        p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score
    ORDER BY 
        p.Score DESC
)
SELECT 
    cr.Title,
    cr.CreationDate,
    cr.ViewCount,
    cr.AnswerCount,
    cr.Score,
    pu.DisplayName AS PopularUser,
    cr.TotalComments,
    cr.AvgCommentLength,
    cr.CloseReasons
FROM 
    CombinedResults cr
JOIN 
    PopularUsers pu ON cr.ViewCount > pu.Reputation
WHERE 
    pu.Reputation IS NOT NULL
ORDER BY 
    cr.ViewCount DESC
LIMIT 50;
