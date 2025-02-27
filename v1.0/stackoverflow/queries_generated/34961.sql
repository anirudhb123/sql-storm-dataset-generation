WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RowNum
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Focusing on post closure and reopening
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts created in the last 30 days
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS EditCount,  -- Counting suggested edits
        COUNT(DISTINCT b.Id) AS BadgeCount  -- Counting the number of badges per user
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
JoinResults AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ru.DisplayName AS ActiveUser,
        ru.EditCount,
        ru.BadgeCount,
        COALESCE(rp.UpVotes - rp.DownVotes, 0) AS NetVotes,
        CASE 
            WHEN rph.PostId IS NOT NULL THEN 'Closed/Opened'
            ELSE 'Active'
        END AS Status
    FROM 
        RecentPosts rp
    LEFT JOIN 
        ActiveUsers ru ON rp.PostId IN (SELECT PostId FROM RecursivePostHistory rph WHERE rph.RowNum = 1)
    LEFT JOIN 
        RecursivePostHistory rph ON rp.PostId = rph.PostId
)
SELECT 
    j.Title,
    j.Score,
    j.ViewCount,
    j.ActiveUser,
    j.EditCount,
    j.BadgeCount,
    j.NetVotes,
    j.Status
FROM 
    JoinResults j
WHERE 
    j.NetVotes > 0  -- Filter to show only posts with positive net votes
ORDER BY 
    j.Score DESC, j.ViewCount DESC;  -- Order by score and view count
