WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserWithMostPosts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        OwnerUserId
    ORDER BY 
        TotalPosts DESC
    LIMIT 1
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Edit Title' THEN ph.CreationDate END) AS LastEditTitleDate,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastCloseDate,
        COUNT(CASE WHEN phh.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN uwp.TotalPosts IS NOT NULL THEN uwp.TotalPosts 
        ELSE 0 
    END AS UserTotalPosts,
    phs.LastEditTitleDate,
    phs.LastCloseDate,
    phs.CloseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserWithMostPosts uwp ON rp.OwnerUserId = uwp.OwnerUserId 
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 5 -- Get the top 5 posts per user
ORDER BY 
    rp.UpVotes DESC NULLS LAST;
