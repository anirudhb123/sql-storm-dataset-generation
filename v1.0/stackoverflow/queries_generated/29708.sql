WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as PostRank,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS ClosedCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS ReopenedCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(rp.CommentCount, 0)) AS TotalComments,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.ClosedCount) AS TotalClosed,
        SUM(rp.ReopenedCount) AS TotalReopened
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalClosed,
    ua.TotalReopened,
    CASE 
        WHEN ua.TotalClosed > ua.TotalReopened THEN 
            'More Posts Closed' 
        ELSE 
            'More Posts Reopened' 
    END AS Status,
    ARRAY_AGG(rp.Title ORDER BY rp.CreationDate DESC) AS RecentPostTitles
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
WHERE 
    ua.Reputation > 1000
GROUP BY 
    ua.DisplayName, ua.Reputation, ua.TotalPosts, ua.TotalComments, ua.TotalClosed, ua.TotalReopened
ORDER BY 
    ua.Reputation DESC, ua.TotalPosts DESC;
