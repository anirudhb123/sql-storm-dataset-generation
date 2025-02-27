WITH RecursiveCTE AS (
    -- Recursive CTE to find the hierarchy of posts based on accepted answers
    SELECT 
        Id,
        AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.Id
),
PostStats AS (
    -- Aggregate statistics on posts
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
),
PostHistoryStats AS (
    -- Get post history statistics
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    -- Select top posts based on score and interaction
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.ViewCount, 
        ps.Score, 
        ps.CommentCount, 
        ps.VoteCount, 
        phs.HistoryCount,
        phs.LastEditDate,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Ranking
    FROM 
        PostStats ps
    INNER JOIN 
        PostHistoryStats phs ON ps.PostId = phs.PostId
    WHERE 
        ps.Score > 0
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    tp.HistoryCount,
    tp.LastEditDate,
    CASE 
        WHEN tp.Ranking <= 10 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostType,
    r.Id AS RelatedPostId,
    r.Level AS AnswerLevel
FROM 
    TopPosts tp
LEFT JOIN 
    RecursiveCTE r ON tp.PostId = r.AcceptedAnswerId
WHERE 
    tp.HistoryCount > 5 -- Filter out posts with low edit history
ORDER BY 
    tp.Ranking;
