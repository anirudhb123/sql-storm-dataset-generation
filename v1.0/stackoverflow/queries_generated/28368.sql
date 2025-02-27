WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only considering questions
    GROUP BY 
        p.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Only considering questions
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Score,
    pt.TagsList,
    ra.UserId AS RecentActivityUserId,
    ra.CreationDate AS ActivityDate,
    ra.Comment AS ActivityComment,
    ra.PostHistoryTypeId AS ActivityTypeId
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank <= 5  -- Limiting to the most recent 5 questions per user
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;
