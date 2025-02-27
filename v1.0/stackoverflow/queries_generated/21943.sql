WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (4, 12) THEN 1 END) AS OffensiveOrSpamVotes,
        SUM(v.BountyAmount) AS TotalBountyReceived
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Tags) AS UniqueTags,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        COALESCE(ps.CommentCount, 0) AS TotalComments,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COUNT(ps.PostId) AS TotalPosts,
        COUNT(DISTINCT u.Tags) AS UniqueTagsPosted
    FROM 
        UserVoteStats us
    LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
    GROUP BY 
        us.UserId, us.DisplayName
),
AggregatedData AS (
    SELECT 
        u.DisplayName,
        ups.TotalPosts,
        ups.TotalComments,
        ups.TotalScore,
        ups.UniqueTagsPosted,
        uvs.UpVotes - uvs.DownVotes AS NetVotes,
        CASE
            WHEN ups.TotalPosts = 0 THEN 0
            ELSE (ups.TotalScore::float / ups.TotalPosts)
        END AS AverageScorePerPost
    FROM 
        UserPostStats ups
    JOIN UserVoteStats uvs ON ups.UserId = uvs.UserId
)
SELECT 
    ad.DisplayName,
    ad.TotalPosts,
    ad.TotalComments,
    ad.TotalScore,
    ad.UniqueTagsPosted,
    ad.NetVotes,
    ad.AverageScorePerPost,
    CASE 
        WHEN ad.AverageScorePerPost IS NULL THEN 'No Posts'
        WHEN ad.AverageScorePerPost > 5 THEN 'High Score'
        WHEN ad.AverageScorePerPost BETWEEN 1 AND 5 THEN 'Moderate Score'
        ELSE 'Needs Improvement'
    END AS ScoreCategory
FROM 
    AggregatedData ad
WHERE 
    ad.TotalPosts > 0 
    OR (ad.NetVotes IS NOT NULL AND ad.NetVotes <> 0)
ORDER BY 
    ad.TotalScore DESC, ad.DisplayName
LIMIT 100;

-- Include a strange outer join with a non-existing condition for performance benchmarking
SELECT 
    p.Title, 
    p.ViewCount,
    COALESCE(c.Text, 'No Comments') AS CommentText,
    CASE 
        WHEN pv.TotalVotes IS NULL THEN 'Unknown Voting'
        ELSE 'Vote Data Available'
    END AS VoteDataStatus
FROM 
    Posts p
LEFT JOIN Comments c ON p.Id = c.PostId AND c.UserId IS NULL
LEFT JOIN (
    SELECT 
        PostId, COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
) pv ON p.Id = pv.PostId
WHERE 
    p.CreationDate >= '2023-01-01'
    AND (p.Body IS NOT NULL OR p.Title LIKE '%sql%')
ORDER BY 
    p.ViewCount DESC;
