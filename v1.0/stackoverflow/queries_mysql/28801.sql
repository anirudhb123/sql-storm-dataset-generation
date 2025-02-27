
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
        @row_num := IF(@prev_tag = p.Tags, @row_num + 1, 1) AS Rank,
        @prev_tag := p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_num := 0, @prev_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.Score
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostsCount,
        AVG(LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS AvgTagsPerPost
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 AS n FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a, 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount,
        GROUP_CONCAT(DISTINCT crt.Name SEPARATOR ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS UNSIGNED) = crt.Id 
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
    TagStatistics ts ON rp.Tags LIKE CONCAT('%', ts.TagName, '%')
LEFT JOIN 
    PostClosureReasons pcr ON rp.PostId = pcr.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Tags, rp.CommentCount DESC, rp.UpVotes DESC;
