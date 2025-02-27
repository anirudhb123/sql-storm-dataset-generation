WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.AcceptedAnswerId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select only Questions
    
    UNION ALL
    
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.LastActivityDate,
        a.Score,
        p.AcceptedAnswerId,
        Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts p ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Ensure we still only connect answers to their questions
), 

PostStats AS (
    SELECT 
        r.Id,
        r.Title,
        r.OwnerUserId,
        u.Reputation,
        r.CreationDate,
        r.LastActivityDate,
        r.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY r.OwnerUserId ORDER BY r.Score DESC) AS RankByScore
    FROM 
        RecursivePostCTE r
    LEFT JOIN 
        Comments c ON r.Id = c.PostId
    LEFT JOIN 
        Votes v ON r.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Count only BountyStart and BountyClose votes
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
    WHERE 
        r.Score > 0  -- Filter for posts with score greater than zero
    GROUP BY 
        r.Id, r.Title, r.OwnerUserId, u.Reputation, r.CreationDate, r.LastActivityDate, r.Score
), 

RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.TotalBounty DESC) AS BountyRank
    FROM 
        PostStats ps
)

SELECT 
    p.Title,
    u.DisplayName,
    ps.Reputation,
    ps.CommentCount,
    ps.Score,
    ps.TotalBounty,
    ps.RankByScore,
    r.BountyRank
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
WHERE 
    ps.CommentCount > 5
    AND r.BountyRank <= 10  -- Top 10 bounty-ranked posts
    AND ps.RankByScore = 1  -- Only get the highest ranked post per user
ORDER BY 
    r.BountyRank;

