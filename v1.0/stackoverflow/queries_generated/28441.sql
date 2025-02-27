WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Filtering for questions only
    GROUP BY 
        p.Id
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.CommentCount, 0)) AS AvgComments,
        AVG(COALESCE(p.UpVotes, 0)) AS AvgUpVotes,
        AVG(COALESCE(p.DownVotes, 0)) AS AvgDownVotes
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.PostTypeId = 1  -- Considering questions only
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgComments,
    ts.AvgUpVotes,
    ts.AvgDownVotes
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%<', ts.TagName, '>%')
WHERE 
    rp.UserPostRank <= 5  -- Top 5 latest questions per user
ORDER BY 
    rp.CreationDate DESC,
    ts.PostCount DESC;

