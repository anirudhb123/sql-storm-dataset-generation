WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
HighEngagementUsers AS (
    SELECT 
        ue.UserId,
        ue.UpVotesCount,
        ue.DownVotesCount,
        ue.BadgesCount,
        ue.PostsCount,
        RANK() OVER (ORDER BY (ue.UpVotesCount - ue.DownVotesCount) DESC, ue.BadgesCount DESC, ue.PostsCount DESC) AS EngagementRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.UpVotesCount > ue.DownVotesCount
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        DATE_TRUNC('month', p.CreationDate) AS PostMonth,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, DATE_TRUNC('month', p.CreationDate)
),
TopPostAnalytics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        pa.CloseReopenCount,
        ue.UserId,
        ue.UpVotesCount,
        ue.BadgesCount
    FROM 
        RankedPosts rp
    JOIN 
        HighEngagementUsers ue ON rp.RecentRank <= 5 AND rp.OwnerUserId = ue.UserId
    JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
)
SELECT 
    tpa.Title,
    tpa.CreationDate,
    tpa.ViewCount,
    tpa.CommentCount,
    tpa.CloseReopenCount,
    tpa.UpVotesCount,
    tpa.BadgesCount,
    CASE 
        WHEN tpa.CloseReopenCount > 0 THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(NULLIF(ua.EmailHash, ''), 'No Email') AS UserEmailHash
FROM 
    TopPostAnalytics tpa
LEFT JOIN 
    Users ua ON tpa.UserId = ua.Id
WHERE 
    tpa.ViewCount > 1000
ORDER BY 
    tpa.ViewCount DESC, tpa.CreationDate DESC
LIMIT 10;
