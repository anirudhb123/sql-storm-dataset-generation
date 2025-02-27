WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
), RecentActivities AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS RecentEditDate,
        ph.UserDisplayName AS LastEditor,
        pt.Name AS PostHistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.CommentCount,
    rp.TagsList,
    ra.RecentEditDate,
    ra.LastEditor,
    ra.PostHistoryType,
    ra.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
WHERE 
    rp.OwnerRank <= 5 -- Top 5 posts per user based on score
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100; -- Limit to 100 results for benchmarking
