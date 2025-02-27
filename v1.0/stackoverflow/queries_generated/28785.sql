WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(c.Id) AS Comment_Count,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATEADD(year, -1, GETDATE()) -- Last year posts
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TagStatistics AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(COALESCE(SUBSTRING(p.Body, CHARINDEX('<p>', p.Body) + 3, CHARINDEX('</p>', p.Body) - CHARINDEX('<p>', p.Body) - 3), '') , 0)) AS AvgBodyLength
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(p.Tags, ',') AS tag
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        tag.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Author,
    rp.Comment_Count,
    rp.UpVotes,
    rp.DownVotes,
    ts.TagName,
    ts.PostCount,
    ts.AvgBodyLength
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' + ts.TagName + '%'
WHERE 
    rp.rn = 1 -- Using only the latest version of each post
ORDER BY 
    rp.UpVotes DESC, 
    rp.Comment_Count DESC;
