WITH RecursivePosts AS (
    SELECT 
        Id, 
        Title, 
        BODY, 
        ParentId, 
        CreationDate, 
        OwnerUserId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.Body, 
        p.ParentId, 
        p.CreationDate, 
        p.OwnerUserId,
        rp.Level + 1
    FROM
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(COALESCE(v.CreationDate, CURRENT_TIMESTAMP)) AS AvgVoteDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        post.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 52 THEN 1 ELSE 0 END) AS IsHotQuestion
    FROM 
        Posts post
    LEFT JOIN 
        PostHistory ph ON post.Id = ph.PostId
    GROUP BY 
        post.Id, p.Title
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalBounty,
        RANK() OVER (ORDER BY ua.PostCount DESC) AS PostRank
    FROM 
        UserActivity ua
)
SELECT 
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    u.DisplayName AS Author,
    ph.EditCount,
    ph.IsClosed,
    ph.IsHotQuestion,
    ru.PostCount AS AuthorPostCount,
    ru.TotalBounty AS AuthorTotalBounty,
    rk.PostRank
FROM 
    RecursivePosts rp
JOIN 
    PostHistoryStats ph ON rp.Id = ph.PostId
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    RankedUsers ru ON u.Id = ru.UserId
LEFT JOIN 
    Votes v ON rp.Id = v.PostId
WHERE 
    rp.CreationDate >= '2023-01-01'
    AND ru.PostRank <= 10
ORDER BY 
    PostTitle ASC, 
    Author ASC;
