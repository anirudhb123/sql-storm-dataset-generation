WITH EnhancedPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COALESCE(au.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(ad.DownVoteCount, 0) AS DownVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) au ON p.Id = au.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS DownVoteCount FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) ad ON p.Id = ad.PostId
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0 -- Checks if TagName is part of the Tags string
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Tracking title/body/tag edits
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts created within the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
BenchmarkResults AS (
    SELECT 
        E.PostId,
        E.Title,
        E.CreationDate,
        E.ViewCount,
        E.Score,
        E.TagList,
        E.UpVoteCount,
        E.DownVoteCount,
        E.CommentCount,
        E.EditCount,
        CASE 
            WHEN E.Score > 100 THEN 'Highly Active'
            WHEN E.Score BETWEEN 50 AND 100 THEN 'Moderately Active'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        EnhancedPostStats E
)
SELECT 
    B.ActivityLevel,
    COUNT(*) AS TotalPosts,
    AVG(B.ViewCount) AS AverageViews,
    AVG(B.UpVoteCount) AS AverageUpVotes,
    AVG(B.DownVoteCount) AS AverageDownVotes,
    AVG(B.CommentCount) AS AverageComments,
    AVG(B.EditCount) AS AverageEdits
FROM 
    BenchmarkResults B
GROUP BY 
    B.ActivityLevel
ORDER BY 
    FIELD(B.ActivityLevel, 'Highly Active', 'Moderately Active', 'Low Activity');
