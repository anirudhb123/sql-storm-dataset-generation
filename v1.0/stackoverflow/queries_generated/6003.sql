WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
), PostAnalytics AS (
    SELECT 
        pos.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(v.CreationDate) AS AverageVoteTime
    FROM 
        RankedPosts pos
    LEFT JOIN 
        Comments c ON c.PostId = pos.PostId
    LEFT JOIN 
        Badges b ON b.UserId = pos.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = pos.PostId
    WHERE 
        pos.PostRank = 1 -- Getting only the latest post per user
    GROUP BY 
        pos.PostId
)
SELECT 
    pa.PostId,
    p.Title,
    p.CreationDate,
    pa.CommentCount,
    pa.BadgeCount,
    pa.TotalBounty,
    pa.AverageVoteTime,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = p.OwnerUserId AND PostTypeId = 1) AS TotalUserQuestions
FROM 
    PostAnalytics pa
JOIN 
    Posts p ON p.Id = pa.PostId
ORDER BY 
    pa.CommentCount DESC, 
    pa.TotalBounty DESC
LIMIT 10;
