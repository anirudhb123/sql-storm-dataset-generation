WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT us.Id) AS TotalPosts,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users us ON p.OwnerUserId = us.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        EXTRACT(EPOCH FROM (now() - p.CreationDate)) / 86400 AS AgeInDays,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate ASC) AS PostOrder
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.UpVoteCount,
    u.DownVoteCount,
    ps.PostId,
    ps.Title,
    ps.AgeInDays,
    ps.UpVoteCount AS PostUpVotes,
    ps.DownVoteCount AS PostDownVotes,
    CASE 
        WHEN ps.AgeInDays > 365 THEN 'Old Post'
        WHEN ps.AgeInDays BETWEEN 30 AND 365 THEN 'Moderate Post'
        ELSE 'Recent Post'
    END AS PostAgeCategory,
    CASE 
        WHEN ps.UpVoteCount - ps.DownVoteCount > 0 THEN 'Positive Sentiment'
        WHEN ps.UpVoteCount - ps.DownVoteCount < 0 THEN 'Negative Sentiment'
        ELSE 'Neutral Sentiment'
    END AS SentimentAnalysis,
    'User ID: ' || u.UserId || ', Vote Difference: ' || (u.UpVoteCount - u.DownVoteCount) AS UserInfo
FROM 
    UserVoteCounts u
JOIN 
    PostStatistics ps ON u.UserId = ps.OwnerUserId
WHERE 
    u.VoteRank <= 10
    AND ps.PostOrder = 1
ORDER BY 
    ps.AgeInDays DESC, 
    u.VoteRank;

