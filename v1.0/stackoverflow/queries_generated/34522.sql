WITH RecursivePosts AS (
    -- Recursive CTE to get hierarchy of posts (Questions and Answers)
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.CreationDate,
        rp.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePosts rp ON p2.ParentId = rp.Id
    WHERE 
        p2.PostTypeId = 2 -- Answers
),
PostDetails AS (
    -- Get post details along with user reputation
    SELECT 
        r.Id AS PostId,
        r.Title,
        r.CreationDate,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(ph.CreationDate, NULL) AS LastEditDate,
        COALESCE(phh.UserDisplayName, 'Community User') AS LastEditedBy
    FROM 
        RecursivePosts r
    LEFT JOIN 
        Posts p ON r.Id = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Title and Body edits
    LEFT JOIN 
        PostHistory phh ON phh.PostId = p.Id AND phh.CreationDate = (
            SELECT MAX(CreationDate)
            FROM PostHistory
            WHERE PostId = p.Id AND PostHistoryTypeId IN (4, 5)
        )
),
PostStats AS (
    -- Aggregate stats for posts
    SELECT 
        pd.PostId,
        pd.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        PostDetails pd
    LEFT JOIN 
        Comments c ON pd.PostId = c.PostId
    LEFT JOIN 
        Votes v ON pd.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        pd.PostId, pd.Title
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    u.Reputation AS OwnerReputation,
    ps.TotalBounties,
    pd.LastEditDate,
    pd.LastEditedBy,
    CASE 
        WHEN ps.CommentCount > 10 THEN 'Highly Active'
        WHEN ps.CommentCount > 5 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    (SELECT COUNT(*) FROM Posts p WHERE p.ParentId = ps.PostId) AS RelatedAnswers
FROM 
    PostStats ps
JOIN 
    Posts p ON ps.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    ps.RankByComments <= 10 -- Top 10 posts by comments
ORDER BY 
    ps.CommentCount DESC;
