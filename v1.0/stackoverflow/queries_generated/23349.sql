WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        p.Id
),
RecentPosts AS (
    SELECT 
        PostId, 
        Title, 
        Rank
    FROM 
        RankedPosts
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        unnest(Tags) AS TagName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
TagCount AS (
    SELECT 
        TagName, 
        COUNT(*) AS Count
    FROM 
        TopTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 1
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 'Closed/Reopen/Deleted'
            ELSE 'Other'
        END AS ChangeType
    FROM 
        PostHistory ph
)
SELECT 
    p.PostId,
    p.Title,
    p.Rank,
    COALESCE(tc.Count, 0) AS TagOccurrence,
    ph.ChangeType,
    ph.CreationDate AS HistoryCreation,
    u.DisplayName AS UserName,
    MAX(ph.UserId) FILTER (WHERE ph.ChangeType = 'Closed/Reopen/Deleted') OVER (PARTITION BY p.PostId) AS LastEditBy
FROM 
    RecentPosts p
LEFT JOIN 
    TagCount tc ON tc.TagName = ANY(ARRAY(SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))))
LEFT JOIN 
    PostHistories ph ON ph.PostId = p.PostId
LEFT JOIN 
    Users u ON u.Id = ph.UserId
WHERE 
    (p.Rank <= 3 OR EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 2))
ORDER BY 
    p.CreationDate DESC, p.Score DESC;
