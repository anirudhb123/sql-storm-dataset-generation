WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId = 1), 0) AS AcceptedAnswers,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE())
),
TopTags AS (
    SELECT 
        TAG.TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(p.Tags, ',') AS TAG
    GROUP BY 
        TAG.TagName
    HAVING 
        COUNT(p.Id) > 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UpVotes,
    us.DownVotes,
    us.AcceptedAnswers,
    us.TotalPosts,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    th.TagCount,
    phs.HistoryTypes,
    phs.EditCount,
    phs.LastEditDate
FROM 
    UserScores us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.RN = 1
LEFT JOIN 
    TopTags th ON th.TagCount IS NOT NULL
LEFT JOIN 
    PostHistorySummary phs ON us.UserId = phs.PostId
WHERE 
    us.Reputation > 1000
    AND (us.UpVotes - us.DownVotes) > 0
ORDER BY 
    us.Reputation DESC, us.DisplayName ASC;
