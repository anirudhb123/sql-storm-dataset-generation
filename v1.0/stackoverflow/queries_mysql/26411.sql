
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.Score > 0 
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        GROUP_CONCAT(DISTINCT t.TagName) AS RelatedTags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1)) AS tag
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
              UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
             CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n - 1) AS tag 
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.RelatedTags,
    CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive Engagement'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, ps.CommentCount DESC;
