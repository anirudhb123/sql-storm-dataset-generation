WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ParentId,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostStatistics AS (
    SELECT 
        ph.PostId,
        COUNT(c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,  -- UpMod votes
        SUM(v.VoteTypeId = 3) AS TotalDownvotes  -- DownMod votes
    FROM 
        Posts ph
    LEFT JOIN 
        Comments c ON ph.Id = c.PostId
    LEFT JOIN 
        Votes v ON ph.Id = v.PostId
    GROUP BY 
        ph.Id
),
TopPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ps.TotalComments,
        ps.TotalUpvotes,
        ps.TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY ps.TotalUpvotes DESC) AS UpvoteRank,
        ROW_NUMBER() OVER (ORDER BY ps.TotalComments DESC) AS CommentRank
    FROM 
        Posts ph
    JOIN 
        PostStatistics ps ON ph.Id = ps.PostId
    WHERE 
        ph.CreationDate >= DATEADD(YEAR, -5, GETDATE())  -- Posts from the last 5 years
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Comment,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
            ELSE 'Edited'
        END AS ChangeType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.TotalComments,
    tp.TotalUpvotes,
    tp.TotalDownvotes,
    p.UserId AS PostOwnerId,
    ph.UserDisplayName AS LastEditor,
    ph.HistoryDate,
    ph.ChangeType,
    CASE 
        WHEN tp.UpvoteRank <= 10 THEN 'Top 10 by Upvotes'
        WHEN tp.CommentRank <= 10 THEN 'Top 10 by Comments'
        ELSE 'Other'
    END AS PostRanking
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails ph ON tp.PostId = ph.PostId
ORDER BY 
    tp.UpvoteRank, tp.CommentRank;
