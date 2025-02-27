WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        t.TagName
), 
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.UpVotes,
        rp.DownVotes,
        ts.TagCount,
        ts.TotalViews,
        ts.AvgScore
    FROM 
        RankedPosts rp
    JOIN 
        TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%' 
    WHERE 
        rp.RowNum <= 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.UpVotes,
    rp.DownVotes,
    ts.TagCount,
    ts.TotalViews,
    ts.AvgScore
FROM 
    RecentPosts rp
JOIN 
    (SELECT DISTINCT Tags FROM Posts WHERE PostTypeId = 1) AS p_tags
ON 
    rp.Tags LIKE '%' || p_tags.Tags || '%'
ORDER BY 
    rp.CreationDate DESC;
