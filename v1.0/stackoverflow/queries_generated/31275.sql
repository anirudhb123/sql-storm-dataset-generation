WITH RECURSIVE PostRankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        RANK() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'  -- Filter for posts in the last year
    GROUP BY 
        p.Id, p.Title
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10  -- Only include users with more than 10 posts
)

SELECT 
    p.PostId,
    p.Title,
    p.UpVotes,
    p.DownVotes,
    p.Rank,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    CASE 
        WHEN p.Rank <= 10 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostRankings p
JOIN 
    TopUsers u ON p.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
WHERE 
    EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = p.PostId AND c.Score > 0) -- Only include posts with positive comments
ORDER BY 
    p.Rank, u.PostCount DESC
LIMIT 50;

