
WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT LEFT(t.TagName, 25)) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT IF(ph.PostHistoryTypeId IN (10, 11, 12), ph.Id, NULL)) AS ClosedOrReopenedCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) numbers
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, u.DisplayName
),
RankedPosts AS (
    SELECT 
        PostID,
        Title,
        Body,
        OwnerDisplayName,
        CreationDate,
        LastActivityDate,
        Tags,
        CommentCount,
        ClosedOrReopenedCount,
        @rank := IF(@prev_last_activity = LastActivityDate, @rank, @rank + 1) AS ActivityRank,
        @prev_last_activity := LastActivityDate
    FROM 
        ProcessedPosts, (SELECT @rank := 0, @prev_last_activity := NULL) r
    ORDER BY LastActivityDate DESC
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Tags,
    rp.CommentCount,
    rp.ClosedOrReopenedCount,
    CASE 
        WHEN rp.ClosedOrReopenedCount > 0 THEN 'Closed or Reopened'
        ELSE 'Active'
    END AS Status
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount > 10 AND
    rp.ActivityRank <= 100 
ORDER BY 
    rp.ActivityRank;
