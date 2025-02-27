WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with a positive score
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(RA.CommentCount, 0) AS RecentComments,
        COALESCE(RA.UpVoteCount, 0) AS RecentUpVotes,
        COALESCE(RA.DownVoteCount, 0) AS RecentDownVotes,
        COALESCE(PH.EditCount, 0) AS TotalEdits,
        COALESCE(PH.LastEditDate, '1900-01-01'::timestamp) AS LastEditDate
    FROM 
        Users u
    LEFT JOIN 
        RecentActivity RA ON u.Id = RA.OwnerUserId
    LEFT JOIN 
        PostHistoryData PH ON PH.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    WHERE 
        u.Reputation > 100 -- Only users with reputation greater than 100
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.RecentComments,
    us.RecentUpVotes,
    us.RecentDownVotes,
    us.TotalEdits,
    us.LastEditDate,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViews
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.RN = 1
ORDER BY 
    us.RecentComments DESC,
    us.RecentUpVotes DESC,
    us.RecentDownVotes DESC;
