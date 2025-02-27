WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalBounties 
    FROM 
        UserActivity 
    WHERE 
        ActivityRank <= 10
), 
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS AuthorName,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
), 
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.UserId IS NULL THEN 1 ELSE 0 END) AS AnonymousComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    au.DisplayName,
    au.Reputation,
    au.PostCount,
    au.TotalBounties,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    c.CommentCount,
    COALESCE(c.AnonymousComments, 0) AS AnonymousCommentCount
FROM 
    ActiveUsers au
JOIN 
    RecentPosts rp ON au.UserId = rp.AuthorName
LEFT JOIN 
    PostComments c ON rp.PostId = c.PostId
WHERE 
    rp.RecentRank <= 5
ORDER BY 
    au.Reputation DESC, 
    rp.RecentPostDate DESC
LIMIT 50;

WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ','))
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        t.TagName
), 
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalBounties,
    cp.Title AS RecentlyClosedPostTitle,
    cp.LastClosedDate
FROM 
    TagStats ts
LEFT JOIN 
    ClosedPosts cp ON ts.PostCount > 0
ORDER BY 
    ts.TotalBounties DESC, 
    ts.PostCount DESC;
