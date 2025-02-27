WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2 -- Only answers
),
AggregatedScores AS (
    SELECT 
        r.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS VoteScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RecursivePostCTE r
    LEFT JOIN 
        Votes v ON r.Id = v.PostId
    LEFT JOIN 
        Comments c ON r.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = r.OwnerUserId
    GROUP BY 
        r.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        AVG(r.VoteScore) OVER (PARTITION BY r.Level) AS AvgVoteScore,
        a.CommentCount,
        a.BadgeCount
    FROM 
        RecursivePostCTE p
    LEFT JOIN 
        AggregatedScores a ON p.Id = a.PostId
),

RecentPostDetails AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY LastActivityDate DESC) AS RecentRank
    FROM 
        PostDetails
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.AvgVoteScore,
    rp.CommentCount,
    rp.BadgeCount,
    CASE 
        WHEN rp.Score > 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RecentPostDetails rp
WHERE 
    rp.RecentRank <= 10 -- Get the top 10 recent posts
ORDER BY 
    rp.LastActivityDate DESC;
