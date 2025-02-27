WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY COUNT(DISTINCT v.Id) DESC) AS RankByTag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(DISTINCT rp.PostId) AS PostCount,
        AVG(rp.UpVotes - rp.DownVotes) AS AvgScore
    FROM 
        RankedPosts rp
    INNER JOIN 
        PopularTags pt ON pt.Tag = ANY(string_to_array(rp.Tags, ',')) 
    GROUP BY 
        Tag
)
SELECT 
    ts.Tag,
    ts.PostCount,
    ts.AvgScore,
    COUNT(*) filter (WHERE rp.RankByTag <= 5) AS Top5PostsCount
FROM 
    TagStatistics ts
LEFT JOIN 
    RankedPosts rp ON ts.Tag = ANY(string_to_array(rp.Tags, ','))
GROUP BY 
    ts.Tag, ts.PostCount, ts.AvgScore
HAVING 
    PostCount > 10
ORDER BY 
    AvgScore DESC
LIMIT 10;
