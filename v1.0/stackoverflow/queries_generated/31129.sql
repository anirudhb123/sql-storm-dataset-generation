WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        Score,
        AcceptedAnswerId,
        ParentId,
        OwnerUserId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Base case: top-level questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AcceptedAnswerId,
        p.ParentId,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id  -- Recursive case: answers
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(a.OwnerDisplayName, 'No accepted answer') AS AcceptedAnswerOwner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id  -- Joining to get the accepted answer details
    LEFT JOIN 
        Comments c ON p.Id = c.PostId  -- Counting comments
    LEFT JOIN 
        Votes v ON p.Id = v.PostId  -- Joining votes to count them
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, a.OwnerDisplayName
),
QualifiedPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.Score,
        pm.AcceptedAnswerOwner,
        pm.CommentCount,
        pm.UpVotes,
        pm.DownVotes,
        p.OwnerUserId,
        CASE 
            WHEN p.Score >= 5 THEN 'high'
            WHEN p.Score BETWEEN 1 AND 4 THEN 'medium'
            ELSE 'low'
        END AS ScoreCategory
    FROM 
        PostMetrics pm
    JOIN 
        Posts p ON pm.PostId = p.Id
    WHERE 
        pm.ViewCount >= 100  -- Filtering for posts with significant views
)
SELECT 
    qp.PostId,
    qp.Title,
    qp.ViewCount,
    qp.Score,
    qp.AcceptedAnswerOwner,
    qp.CommentCount,
    qp.UpVotes,
    qp.DownVotes,
    qp.ScoreCategory,
    COALESCE(uh.TotalBadges, 0) AS UserBadges,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
FROM 
    QualifiedPosts qp
LEFT JOIN 
    (SELECT 
         UserId, COUNT(*) AS TotalBadges 
     FROM 
         Badges 
     GROUP BY 
         UserId) uh ON qp.OwnerUserId = uh.UserId  -- Aggregate user badges
LEFT JOIN 
    PostLinks pl ON qp.PostId = pl.PostId  -- Counting related posts
GROUP BY 
    qp.PostId, qp.Title, qp.ViewCount, qp.Score, qp.AcceptedAnswerOwner,
    qp.CommentCount, qp.UpVotes, qp.DownVotes, qp.ScoreCategory,
    uh.TotalBadges
ORDER BY 
    qp.Score DESC, qp.ViewCount DESC;  -- Final ordering by score and view count
