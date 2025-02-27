WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 3600) AS AverageAgeInHours
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(pl.LinkCount, 0) AS RelatedPostsCount
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS LinkCount
        FROM PostLinks
        GROUP BY PostId
    ) pl ON pl.PostId = p.Id
    WHERE p.PostTypeId = 1
),
FinalBenchmark AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AverageAgeInHours,
        ue.UserId,
        ue.DisplayName,
        ue.TotalVotes,
        ue.UpVotes,
        ue.DownVotes,
        pe.PostId,
        pe.Title,
        pe.Score,
        pe.ViewCount,
        pe.CommentCount,
        pe.RelatedPostsCount
    FROM TagStatistics ts
    CROSS JOIN UserVotes ue
    JOIN PostEngagement pe ON pe.PostId IN (
        SELECT Id 
        FROM Posts 
        WHERE Tags LIKE '%' || ts.TagName || '%'
        LIMIT 10 -- limit to first 10 posts for each tag
    )
)
SELECT 
    TagName,
    DisplayName,
    TotalVotes,
    UpVotes,
    DownVotes,
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    RelatedPostsCount,
    AverageAgeInHours
FROM FinalBenchmark
ORDER BY TagName, AverageAgeInHours DESC, TotalVotes DESC;
