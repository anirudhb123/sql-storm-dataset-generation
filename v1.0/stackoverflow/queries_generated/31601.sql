WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        0 AS Level 
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1 
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        (Reputation + UpVotes - DownVotes) AS EffectiveReputation
    FROM 
        Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.EffectiveReputation,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN p.PostTypeId = 1 THEN 'Questions' ELSE 'Others' END ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        UserReputation u ON p.OwnerUserId = u.UserId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.Score, u.EffectiveReputation
),
ClosedQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        RANK() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
)
SELECT 
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.EffectiveReputation AS AuthorReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    ISNULL(cq.CloseDate, 'Not Closed') AS LastClosedDate,
    tp.Rank AS PostRank 
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    ClosedQuestions cq ON tp.PostId = cq.PostId
WHERE 
    tp.Rank <= 5
GROUP BY 
    tp.Title, tp.Score, tp.EffectiveReputation, cq.CloseDate, tp.Rank
ORDER BY 
    tp.Score DESC;
