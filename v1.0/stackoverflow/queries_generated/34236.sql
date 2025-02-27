WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS RN
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Considering close, reopen, and delete actions
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.LastActivityDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty, 
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.LastActivityDate, p.Score
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(u.UpVotes) AS TotalUpvotes,
        SUM(u.DownVotes) AS TotalDownvotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    ua.DisplayName AS OwnerDisplayName,
    ua.TotalViews,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    COALESCE(rph.Id, -1) AS LastEditHistoryId,
    rp.CommentCount,
    rp.TotalBounty,
    CASE 
        WHEN rp.LastActivityDate < CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus,
    ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL) AS ActiveTags
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    RecursivePostHistory rph ON rp.PostId = rph.PostId
LEFT JOIN 
    LATERAL (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(rp.Tags, ',')) AS TagName) t ON TRUE
WHERE 
    rp.Score > 0
GROUP BY 
    rp.PostId, rp.Title, rp.Score, ua.DisplayName, ua.TotalViews, ua.TotalUpvotes, ua.TotalDownvotes, rph.Id
HAVING 
    COUNT(rph.Id) > 2 -- Filter to those who have had multiple closing/reopening/deletion actions
ORDER BY 
    rp.ScoreRank;
