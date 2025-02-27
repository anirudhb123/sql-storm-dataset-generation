WITH TagStatistics AS (
    SELECT 
        TagName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.TagName
),
TagHistory AS (
    SELECT 
        th.TagName,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Tags t
    JOIN 
        PostHistory ph ON ph.Text ILIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
BenchmarkedTags AS (
    SELECT 
        ts.TagName, 
        ts.PostCount,
        ts.CommentCount, 
        ts.UpVotes, 
        ts.DownVotes, 
        CASE 
            WHEN th.HistoryCount IS NOT NULL THEN th.HistoryCount 
            ELSE 0 
        END AS TotalHistoryCount
    FROM 
        TagStatistics ts
    LEFT JOIN 
        TagHistory th ON ts.TagName = th.TagName
)
SELECT 
    TagName,
    PostCount,
    CommentCount,
    UpVotes,
    DownVotes,
    TotalHistoryCount,
    (PostCount + CommentCount + UpVotes - DownVotes + TotalHistoryCount) AS Score
FROM 
    BenchmarkedTags
ORDER BY 
    Score DESC
LIMIT 10;
