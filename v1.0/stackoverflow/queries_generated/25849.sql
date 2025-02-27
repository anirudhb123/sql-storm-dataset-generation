WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.ViewCount
),
PostScores AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        DATEDIFF(DAY, rp.CreationDate, GETDATE()) AS PostAgeDays,
        (rp.ViewCount + (rp.UpVoteCount * 5) - (rp.DownVoteCount * 2) + (rp.CommentCount * 3)) AS EngagementScore
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostID,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.PostAgeDays,
    ps.EngagementScore,
    CASE 
        WHEN ps.EngagementScore > 50 THEN 'High Engagement'
        WHEN ps.EngagementScore BETWEEN 20 AND 50 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostScores ps
WHERE 
    ps.PostAgeDays < 30 -- Select only posts younger than 30 days
ORDER BY 
    ps.EngagementScore DESC
LIMIT 100;
