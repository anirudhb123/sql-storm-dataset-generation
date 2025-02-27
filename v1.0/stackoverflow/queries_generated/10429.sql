-- Performance benchmarking query to analyze Posts, Users, and Votes

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        u.Reputation,
        u.DisplayName AS AuthorDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Get posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation, u.DisplayName
),
PostBenchmark AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        COUNT(PostId) AS TotalPosts
    FROM 
        PostMetrics
)

SELECT 
    *
FROM 
    PostBenchmark;
