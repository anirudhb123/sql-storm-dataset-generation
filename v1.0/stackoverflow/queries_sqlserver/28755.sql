
WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT LEFT(t.TagName, 25), ',') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS ClosedOrReopenedCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    CROSS APPLY 
        (SELECT value AS TagName 
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') 
        WHERE LEN(value) > 0) AS tag_name
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.TagName
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
        RANK() OVER (ORDER BY LastActivityDate DESC) AS ActivityRank
    FROM 
        ProcessedPosts
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
