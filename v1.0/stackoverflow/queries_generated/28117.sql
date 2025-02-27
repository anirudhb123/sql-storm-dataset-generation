-- This query benchmarks string processing capabilities by generating a report on posts 
-- along with aggregated statistics on their tags, usage, and user contributions.

WITH TagStats AS (
    SELECT 
        LOWER(TRIM(tag)) AS NormalizedTag, 
        COUNT(*) AS TagUsageCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS tag
    GROUP BY 
        LOWER(TRIM(tag))
),
PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT bh.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId AND bh.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE()) -- Last 6 months
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.AcceptedAnswerId, p.CreationDate, u.DisplayName
),
PostWithTags AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.OwnerDisplayName,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        t.NormalizedTag,
        t.TagUsageCount
    FROM 
        PostAggregates pa
    LEFT JOIN 
        TagStats t ON EXISTS (
            SELECT 1 FROM STRING_SPLIT(SUBSTRING(pa.Tags, 2, LEN(pa.Tags) - 2), '><') AS tag WHERE LOWER(TRIM(tag)) = t.NormalizedTag
        )
)

SELECT 
    pwt.PostId,
    pwt.Title,
    pwt.OwnerDisplayName,
    pwt.CommentCount,
    pwt.UpVotes,
    pwt.DownVotes,
    STRING_AGG(pwt.NormalizedTag, ', ') AS Tags,
    COUNT(pwt.NormalizedTag) AS TotalTags,
    SUM(pwt.TagUsageCount) AS TotalTagUsages
FROM 
    PostWithTags pwt
GROUP BY 
    pwt.PostId, pwt.Title, pwt.OwnerDisplayName, pwt.CommentCount, pwt.UpVotes, pwt.DownVotes
ORDER BY 
    TotalTags DESC, UpVotes DESC;
