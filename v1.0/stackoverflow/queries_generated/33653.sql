WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        rp.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
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
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName,
        MAX(ph.UserId) AS LastUserId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserDisplayName
)
SELECT 
    rp.Title AS PostTitle,
    rp.Depth,
    COUNT(c.Id) AS CommentCount,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    STRING_AGG(DISTINCT ts.TagName, ', ') AS RelatedTags,
    COALESCE(u.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(u.BadgeNames, 'No Badges') AS UserBadges,
    COALESCE(cp.ClosedDate, 'Open') AS PostStatus,
    CASE 
        WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS Status
FROM 
    RecursivePosts rp
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
LEFT JOIN 
    PostVoteStats pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    UserBadges u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
GROUP BY 
    rp.Id, rp.Title, rp.Depth, pvs.UpVotes, pvs.DownVotes, u.BadgeCount, u.BadgeNames, cp.ClosedDate
ORDER BY 
    rp.Depth, rp.Title;
