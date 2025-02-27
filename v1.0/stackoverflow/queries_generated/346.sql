WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
FilteredUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation >= 1000
),
CommentsSummary AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS TotalComments, 
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    p.Title, 
    u.DisplayName AS Owner, 
    p.CreationDate, 
    p.Score AS PostScore, 
    COALESCE(cs.TotalComments, 0) AS TotalComments, 
    COALESCE(cs.AvgCommentScore, 0) AS AvgCommentScore,
    CASE 
        WHEN p.Score > 50 THEN 'High Score'
        WHEN p.Score BETWEEN 20 AND 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
FROM 
    RankedPosts p
JOIN 
    FilteredUsers u ON p.OwnerUserId = u.Id
LEFT JOIN 
    CommentsSummary cs ON p.Id = cs.PostId
WHERE 
    p.PostRank = 1
ORDER BY 
    p.CreationDate DESC 
LIMIT 25;

-- Additional statistics
WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.DisplayName,
    uv.TotalVotes,
    uv.UpVotes,
    uv.DownVotes,
    CASE 
        WHEN uv.TotalVotes > 100 THEN 'Active Voter'
        WHEN uv.TotalVotes BETWEEN 50 AND 100 THEN 'Moderate Voter'
        ELSE 'New Voter'
    END AS VoterCategory
FROM 
    FilteredUsers u
JOIN 
    UserVotes uv ON u.Id = uv.UserId
ORDER BY 
    uv.TotalVotes DESC;
