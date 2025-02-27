WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ParentId, 
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ParentId, 
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Level AS PostLevel,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(MAX(po.ViewCount), 0) AS MaxViewCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts po ON po.Id = p.AcceptedAnswerId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider posts from the last year
    GROUP BY 
        p.Id, ph.Level, u.DisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.PostLevel,
    pd.OwnerDisplayName,
    pd.Upvotes,
    pd.Downvotes,
    pd.CommentCount,
    pd.MaxViewCount,
    ur.Reputation,
    ur.BadgeCount
FROM 
    PostDetails pd
JOIN 
    UserReputation ur ON pd.OwnerDisplayName = ur.DisplayName
ORDER BY 
    pd.Upvotes DESC, pd.CommentCount DESC, ur.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;  -- Pagination for top 100 results
This query showcases the following constructs:

1. **Recursive CTE**: `PostHierarchy` to gather nested post details by linking parent-child relationships.
2. **Window Functions**: `ROW_NUMBER()` to rank users based on reputation.
3. **Aggregate Functions**: Computation of upvotes, downvotes, and comment counts for the posts.
4. **Outer Joins**: To gather comments, votes, and badge counts, even if those relations might be null.
5. **Complex Filtering**: Posts from the last year are considered, and ranking is based on multiple criteria. 
6. **NULL Logic**: Usage of `COALESCE` to handle potential nulls in the aggregation.
7. **String Expressions**: To summon user display names and ensure joins are correct.

This query captures complex relationships and gives a performance benchmark of popular posts, integrating user reputations and engagement metrics efficiently.
