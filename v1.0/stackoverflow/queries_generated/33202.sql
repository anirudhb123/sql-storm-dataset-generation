WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        PostTypeId,
        AcceptedAnswerId,
        ParentId,
        CreationDate,
        Score,
        OwnerUserId,
        Title,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id  -- Recursive join for answers
),
UserScoreStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
FilteredPosts AS (
    SELECT 
        p.*,
        p.OwnerUserId,
        ph.Title AS ParentTitle,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.Id AND p.PostTypeId = 2
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' -- Only posts from the last year
)
SELECT 
    u.DisplayName,
    up.UpVotes,
    up.DownVotes,
    COUNT(DISTINCT fp.Id) AS PostsCount,
    MAX(fp.CreationDate) AS LastPostDate,
    COUNT(fp.Id) FILTER (WHERE fp.PostTypeId = 1) AS QuestionsCount,
    COUNT(fp.Id) FILTER (WHERE fp.PostTypeId = 2) AS AnswersCount,
    AVG(fp.Score) AS AvgScore,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY MAX(fp.CreationDate) DESC) AS Rank
FROM 
    UserScoreStatistics up
JOIN 
    Users u ON u.Id = up.UserId
LEFT JOIN 
    FilteredPosts fp ON u.Id = fp.OwnerUserId
GROUP BY 
    u.Id, up.UpVotes, up.DownVotes
ORDER BY 
    Rank, AvgScore DESC;
