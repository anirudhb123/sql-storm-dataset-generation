WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS WikiPosts,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
PostHistoryAnalysis AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(ph.Id) AS RevisionCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11)
    GROUP BY 
        p.Id, ph.PostHistoryTypeId, ph.CreationDate
),
TopUsers AS (
    SELECT 
        UserId, 
        SUM(TotalPosts) AS TotalPostsCount
    FROM 
        UserStatistics
    GROUP BY 
        UserId
    ORDER BY 
        TotalPostsCount DESC
    LIMIT 10
),
StringProcessingBenchmark AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        STRING_AGG(DISTINCT ph.PostHistoryTypeId::varchar, ',') AS PostHistoryTypes,
        SUM(ph.RevisionCount) AS TotalRevisions,
        MAX(LEFT(p.Title, 30)) AS SampleTitleSubstring,
        SUM(CHAR_LENGTH(p.Body)) AS TotalBodyLength
    FROM 
        Users u
    JOIN 
        UserStatistics us ON u.Id = us.UserId
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Id IN (SELECT UserId FROM TopUsers)
    GROUP BY 
        u.Id
)
SELECT 
    DisplayName,
    TotalPosts,
    PostHistoryTypes,
    TotalRevisions,
    SampleTitleSubstring,
    TotalBodyLength,
    TotalBodyLength / NULLIF(TotalPosts, 0) AS AvgBodyLengthPerPost
FROM 
    StringProcessingBenchmark
ORDER BY 
    TotalPosts DESC;
