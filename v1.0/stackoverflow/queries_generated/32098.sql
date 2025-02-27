WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountySpent,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        c.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    COALESCE(phs.PostHistoryTypes, 'None') AS LastPostHistoryTypes,
    COALESCE(DATE_PART('epoch', phs.LastEditDate) / 60, 0) AS LastEditAgeInMinutes,
    ua.DisplayName,
    ua.BadgeCount,
    ua.TotalBountySpent,
    ua.UpvotesReceived
FROM 
    RankedPosts rp
    LEFT JOIN RecentComments rc ON rp.PostId = rc.PostId
    LEFT JOIN PostHistorySummary phs ON rp.PostId = phs.PostId
    LEFT JOIN UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
