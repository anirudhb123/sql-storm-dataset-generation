WITH TagCounts AS (
    SELECT 
        tags.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Tags tags
    JOIN 
        Posts p ON tags.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        (SELECT PostId, SUM(Score) AS UpVotes, SUM(CASE WHEN Score < 0 THEN -Score ELSE 0 END) AS DownVotes
         FROM Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        tags.TagName
)
SELECT 
    tc.TagName,
    tc.PostCount,
    tc.TotalUpVotes,
    tc.TotalDownVotes,
    tc.TotalComments,
    ROUND((tc.TotalUpVotes - tc.TotalDownVotes)::numeric / NULLIF(tc.PostCount, 0), 2) AS AvgScore,
    RANK() OVER (ORDER BY tc.PostCount DESC) AS RankByPostCount
FROM 
    TagCounts tc
WHERE 
    tc.PostCount > 0
ORDER BY 
    AvgScore DESC, 
    tc.PostCount DESC
LIMIT 10;

WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0  -- Only questions with a positive score
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    CONCAT_WS(', ', pd.Tags) AS Tags,
    EXTRACT(EPOCH FROM (NOW() - pd.CreationDate)) / 86400 AS DaysSinceCreation
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC
LIMIT 5;
