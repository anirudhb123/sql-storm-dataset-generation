WITH TagsArray AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
),
TagUsage AS (
    SELECT
        Tag,
        COUNT(*) AS UsageCount,
        ARRAY_AGG(DISTINCT ta.Tag) AS RelatedTags
    FROM 
        TagsArray ta
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 -- Only include tags used more than 5 times
),
TagDetails AS (
    SELECT 
        t.TagName,
        tu.UsageCount,
        t.Count AS TotalCount,
        tu.RelatedTags
    FROM 
        TagUsage tu
    JOIN 
        Tags t ON tu.Tag = t.TagName
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(cc.Id) AS CloseCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Closed or reopened
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory phcc ON p.Id = phcc.PostId AND phcc.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
),
FinalBenchmark AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.CloseCount,
        ps.UpVotes,
        ps.DownVotes,
        td.TagName,
        td.UsageCount,
        td.TotalCount,
        td.RelatedTags
    FROM 
        PostStatistics ps
    JOIN 
        TagDetails td ON td.TagName = ANY(td.RelatedTags)
    ORDER BY 
        ps.UpVotes DESC,
        ps.CommentCount DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    CloseCount,
    UpVotes,
    DownVotes,
    TagName,
    UsageCount,
    TotalCount
FROM 
    FinalBenchmark
LIMIT 100;
