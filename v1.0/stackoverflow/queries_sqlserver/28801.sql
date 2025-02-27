
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.Score
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(*) AS PostsCount,
        AVG(LEN(T.Tags) - LEN(REPLACE(T.Tags, '><', '')) + 1) AS AvgTagsPerPost
    FROM 
        Posts p
    CROSS APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(p.Tags, '><')
    ) AS T
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        T.TagName
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON TRY_CAST(ph.Comment AS INT) = crt.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ts.PostsCount AS TotalPostsForTag,
    ts.AvgTagsPerPost AS AvgTagsPerPost,
    COALESCE(pcr.ClosureCount, 0) AS TotalClosures,
    COALESCE(pcr.Reasons, 'No closures') AS ClosureReasons
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' + ts.TagName + '%'
LEFT JOIN 
    PostClosureReasons pcr ON rp.PostId = pcr.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Tags, rp.CommentCount DESC, rp.UpVotes DESC;
