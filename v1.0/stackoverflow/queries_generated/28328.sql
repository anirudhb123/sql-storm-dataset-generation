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
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tagName ON t.TagName = tagName
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS ClosureReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (24, 35) THEN 1 ELSE 0 END) AS EditsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.ViewCount,
    rp.Score,
    Tags,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosureDate,
    COALESCE(cp.ClosureReason, 'N/A') AS ClosureReason,
    ua.PostsCreated,
    ua.EditsMade,
    ua.TotalUpvotes
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserActivity ua ON rp.OwnerDisplayName = ua.DisplayName
WHERE 
    rp.Rank <= 5 -- Top 5 posts by view count in each post type
ORDER BY 
    rp.PostId;
