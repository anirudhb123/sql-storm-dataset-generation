WITH RecursivePosts AS (
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COALESCE(NULLIF(pl.LinkTypeId, 3), -1) AS LinkTypeId,  -- -1 if not a duplicate, using NULLIF to handle specific LinkType case
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        RANK() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM 
        Tags t
    WHERE 
        t.Count > 100  -- Filter for popular tags
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        p.Title,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Only considering close, open and delete actions
)

SELECT
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    bu.BadgeCount,
    t.TagName,
    COALESCE(pv.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(pv.DownVoteCount, 0) AS DownVoteCount,
    MIN(p.CommentsCount) AS CommentsCount,
    COUNT(phd.PostHistoryTypeId) FILTER (WHERE phd.PostHistoryTypeId = 10) AS CloseCount,
    COUNT(phd.PostHistoryTypeId) FILTER (WHERE phd.PostHistoryTypeId = 11) AS ReopenCount,
    CASE WHEN AVG(rp.LinkTypeId) > 0 THEN 'Has Links' ELSE 'No Links' END AS LinkStatus
FROM 
    RecursivePosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    BadgedUsers bu ON u.Id = bu.UserId
LEFT JOIN 
    TopTags t ON rp.TagId = t.TagId
LEFT JOIN 
    (SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId) pv ON rp.PostId = pv.PostId
LEFT JOIN 
    (SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentsCount
    FROM 
        Comments c 
    GROUP BY 
        c.PostId) p ON rp.PostId = p.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.RN = 1  -- Only get the most recent version per post
GROUP BY 
    rp.PostId, rp.Title, u.DisplayName, bu.BadgeCount, t.TagName, pv.UpVoteCount, pv.DownVoteCount
HAVING 
    COUNT(DISTINCT rp.ParentId) > 0  -- Only including posts with answers
ORDER BY 
    UpVoteCount DESC, rp.CreationDate DESC;
