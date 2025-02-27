WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(v.BountyAmount) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.vote_summary, 0) AS TotalVotes,
        COALESCE(b.BountyTotal, 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, SUM(VoteTypeId = 2) AS vote_summary FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, SUM(BountyAmount) AS BountyTotal FROM Votes WHERE BountyAmount IS NOT NULL GROUP BY PostId) b ON p.Id = b.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
PostRankings AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        CommentCount,
        TotalVotes,
        TotalBounty,
        RANK() OVER (ORDER BY Score DESC, TotalVotes DESC) AS Rank
    FROM 
        PostDetails
)
SELECT 
    p.Title,
    p.Score,
    p.CommentCount,
    p.TotalVotes,
    p.TotalBounty,
    u.DisplayName AS TopVoter,
    u.VoteCount,
    u.TotalBountySpent,
    CASE 
        WHEN p.TotalVotes > 0 THEN (p.Score / p.TotalVotes) 
        ELSE NULL 
    END AS ScorePerVote,
    CASE 
        WHEN p.CommentCount > 0 THEN ROUND((p.Score::float / NULLIF(p.CommentCount, 0)), 2) 
        ELSE NULL 
    END AS ScorePerComment,
    CASE 
        WHEN b.Count IS NULL THEN 'No Bounty' 
        ELSE 'Bounty Available' 
    END AS BountyStatus
FROM 
    PostRankings p
LEFT JOIN 
    (SELECT 
        UserId, 
        COUNT(*) AS VoteCount, 
        SUM(BountyAmount) AS TotalBountySpent 
    FROM 
        Votes 
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        UserId) u ON p.PostId = u.UserId
LEFT JOIN 
    Badges b ON b.UserId = u.UserId
WHERE 
    p.Rank <= 10 
ORDER BY 
    Score DESC, TotalVotes DESC;
