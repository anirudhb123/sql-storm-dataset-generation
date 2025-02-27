WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(AcceptedAnswers.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            AcceptedAnswerId
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 
            AND AcceptedAnswerId IS NOT NULL
    ) AcceptedAnswers ON p.Id = AcceptedAnswers.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
)

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS TotalQuestions,
    AVG(p.Score) AS AvgQuestionScore,
    SUM(CASE WHEN p.AcceptedAnswerId != -1 THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
    STRING_AGG(pt.Name, ', ') AS PostTypes,
    MAX(rank.RankByUser) AS HighestRank,
    MIN(pt.Name) FILTER (WHERE pt.Class = 1) AS GoldBadgeName, 
    MAX(pt.Name) FILTER (WHERE pt.Class = 3) AS BronzeBadgeName,
    SUM(b.Date IS NOT NULL AND b.TagBased = 1)::int AS TagBasedBadges
FROM 
    Users u
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class IN (1, 3) -- Gold and Bronze badges
LEFT JOIN 
    PostTypes pt ON pt.Id = p.PostTypeId  -- Join to get post types
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.PostId) > 5 -- Only include users with more than 5 questions
ORDER BY 
    AvgQuestionScore DESC, 
    TotalQuestions DESC
LIMIT 
    10;

-- Additional part for performance analysis: Using EXISTS and complex predicates
WITH UserVoteStats AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        EXISTS (
            SELECT 1 
            FROM Posts p 
            WHERE p.Id = v.PostId AND p.CreationDate >= NOW() - INTERVAL '30 days'
        )
    GROUP BY 
        UserId
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    WHERE 
        p.Score > (SELECT AVG(Score) FROM Posts)
)

SELECT 
    u.Id,
    u.DisplayName,
    uv.VoteCount,
    pp.Title,
    pp.ViewCount
FROM 
    Users u
LEFT JOIN 
    UserVoteStats uv ON u.Id = uv.UserId
INNER JOIN 
    PopularPosts pp ON pp.ViewCount > 100 -- Join on posts with views above 100
WHERE 
    (uv.UpVotes IS NOT NULL OR uv.DownVotes IS NOT NULL)
    AND u.EmailHash IS NOT NULL -- users who have a valid email
ORDER BY 
    uv.VoteCount DESC
LIMIT 
    5;
