WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider posts created in the last year
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(u.UpVotes, 0) - COALESCE(u.DownVotes, 0)) AS ReputationScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score AS PostScore,
    rp.CreationDate AS PostCreationDate,
    pt.Name AS PostType,
    ut.UserId AS OwnerId,
    ur.ReputationScore,
    ut.DisplayName AS OwnerDisplayName,
    ct.CloseCount,
    ct.LastClosedDate,
    ptg.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
LEFT JOIN 
    Users ut ON rp.OwnerUserId = ut.Id
LEFT JOIN 
    UserReputation ur ON ut.Id = ur.UserId
LEFT JOIN 
    ClosedPosts ct ON rp.PostId = ct.PostId
JOIN 
    PopularTags ptg ON ptg.PostCount > 5 -- Only include popular tags that are associated with this post
WHERE 
    rp.Rank <= 5 -- Get top 5 posts by score per post type
ORDER BY 
    rp.Score DESC;
