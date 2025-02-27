WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only questions
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(COALESCE(vs.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(vs.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Only questions
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            PostId) vs ON p.Id = vs.PostId
    GROUP BY 
        u.Id
),
TopActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionsAsked,
        us.TotalUpVotes - us.TotalDownVotes AS NetVotes,
        RANK() OVER (ORDER BY us.NetVotes DESC) AS UserRank
    FROM 
        UserStatistics us
    WHERE 
        us.QuestionsAsked > 0
)

SELECT 
    tuku.UserRank,
    tuku.DisplayName,
    COUNT(rp.Id) AS QuestionsRanked,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews
FROM 
    TopActiveUsers tuku
LEFT JOIN 
    RankedPosts rp ON tuku.UserId = rp.OwnerUserId
WHERE 
    tuku.UserRank <= 10  -- Top 10 users
GROUP BY 
    tuku.UserRank, tuku.DisplayName
ORDER BY 
    tuku.UserRank;

-- Optional: Additional statistics for users without questions to analyze engagement
SELECT 
    u.Id,
    u.DisplayName,
    COALESCE(SUM(rp.Score), 0) AS TotalScore,
    COALESCE(COUNT(rp.Id), 0) AS QuestionsAnswered
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2  -- Answers only
LEFT JOIN 
    RankedPosts rp ON p.ParentId = rp.Id
WHERE 
    u.Reputation > 1000  -- Consider users with sufficient reputation
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(p.Id) = 0  -- Users who have not asked questions
ORDER BY 
    TotalScore DESC;
