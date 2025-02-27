WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start with top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Filter for the last year
    GROUP BY 
        p.Id
    HAVING 
        COUNT(DISTINCT v.UserId) > 5 -- More than 5 unique voters
),
ClosedQuestions AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post closed
),
TopCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
    HAVING 
        COUNT(*) > 10  -- More than 10 comments
),
FinalResults AS (
    SELECT 
        tp.*,
        COALESCE(cq.ClosedDate, 'No Closure') AS ClosureStatus,
        COALESCE(tc.TotalComments, 0) AS TotalComments
    FROM 
        TopPosts tp
    LEFT JOIN 
        ClosedQuestions cq ON tp.Id = cq.PostId
    LEFT JOIN 
        TopCommentedPosts tc ON tp.Id = tc.PostId
)
SELECT 
    *,
    CASE 
        WHEN ClosureStatus = 'No Closure' THEN 'Open for Discussion'
        ELSE 'Closed for Comments'
    END AS PostStatus
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;  -- Limit the results

