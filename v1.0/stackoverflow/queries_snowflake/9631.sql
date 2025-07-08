
WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t ON TRUE
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
AggregatedStats AS (
    SELECT
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore,
        SUM(CommentCount) AS TotalComments,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RecentPostStats
)
SELECT 
    r.*,
    a.TotalPosts,
    a.TotalViews,
    a.AverageScore,
    a.TotalComments,
    a.TotalAnswers,
    a.TotalUpVotes,
    a.TotalDownVotes
FROM 
    RecentPostStats r,
    AggregatedStats a
ORDER BY 
    r.ViewCount DESC
LIMIT 10;
