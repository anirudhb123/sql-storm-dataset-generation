
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
        AND p.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.Score
),
TagStatistics AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostsCount,
        AVG(COUNT(*)) OVER () AS AvgTagsPerPost
    FROM 
        Posts p,
        LATERAL SPLIT_TO_TABLE(p.Tags, '><') AS value
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount,
        LISTAGG(DISTINCT crt.Name, ', ') WITHIN GROUP (ORDER BY crt.Name) AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON TRY_CAST(ph.Comment AS INTEGER) = crt.Id 
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
    TagStatistics ts ON POSITION(ts.TagName IN rp.Tags) > 0
LEFT JOIN 
    PostClosureReasons pcr ON rp.PostId = pcr.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Tags, rp.CommentCount DESC, rp.UpVotes DESC;
