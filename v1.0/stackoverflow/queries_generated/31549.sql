WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    AND 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pu.DisplayName AS PopularUser,
    pu.UpVotes AS UserUpVotes,
    pu.TotalPosts AS UserTotalPosts,
    RANK() OVER (ORDER BY rp.Score DESC) AS PostRank,
    pwt.Tags,
    COALESCE(rph.Comment, 'No recent history') AS RecentAction,
    rph.CreationDate AS RecentActionDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularUsers pu ON pu.UserId = rp.PostId
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId = rp.PostId
LEFT JOIN 
    PostWithTags pwt ON pwt.PostId = rp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC;
